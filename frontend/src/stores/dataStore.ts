import { defineStore } from 'pinia'
import type {
  SpaData,
  SpaMetadata,
  SpaPackageTreeNode,
  SpaPackageTree,
  SpaSearchEntry,
  SpaSearchIndex,
  SpaShard,
  SpaSkeletonEntry,
} from '../types'

const SHARD_DIRS: Record<string, string> = {
  class: 'classes',
  enumeration: 'enumerations',
  data_type: 'data_types',
  primitive_type: 'primitive_types',
  interface: 'interfaces',
  package: 'packages',
  diagram: 'diagrams',
  property: 'properties',
}

const FETCH_CONCURRENCY = 12

const inflight = new Map<string, Promise<SpaShard | null>>()

export const useDataStore = defineStore('data', {
  state: () => ({
    metadata: null as SpaMetadata | null,
    packageTree: null as SpaPackageTree | null,
    entries: [] as SpaSkeletonEntry[],
    searchEntries: [] as SpaSearchEntry[],
    elements: {} as Record<string, SpaShard>,
    shardBase: '',
    loaded: false,
  }),

  getters: {
    entriesById(): Record<string, SpaSkeletonEntry> {
      const map: Record<string, SpaSkeletonEntry> = {}
      for (const e of this.entries) map[e.id] = e
      return map
    },

    nodesById(): Record<string, SpaPackageTreeNode> {
      const map: Record<string, SpaPackageTreeNode> = {}
      if (this.packageTree) {
        for (const n of this.packageTree.nodes) map[n.id] = n
      }
      return map
    },

    rootNodes(): SpaPackageTreeNode[] {
      const tree = this.packageTree
      if (!tree) return []
      const map = this.nodesById
      return tree.rootIds.map((id) => map[id]).filter((n) => !!n)
    },
  },

  actions: {
    loadFromEmbedded() {
      const win = window as any
      const raw = win.__SPA_DATA__ as SpaData
      if (!raw) {
        throw new Error('No embedded SPA data found in window.__SPA_DATA__')
      }
      this.metadata = raw.metadata
      this.packageTree = raw.packageTree
      this.entries = raw.entries || []
      this.searchEntries = raw.searchIndex?.entries || []
      this.hydrateShards(raw.shards || [])
      this.loaded = true
    },

    async loadFromSharded(skeletonUrl: string, searchUrl: string, shardBase: string) {
      const [skeletonRes, searchRes] = await Promise.all([
        fetch(skeletonUrl),
        fetch(searchUrl),
      ])
      if (!skeletonRes.ok) {
        throw new Error(`Failed to load ${skeletonUrl}: ${skeletonRes.status}`)
      }
      if (!searchRes.ok) {
        throw new Error(`Failed to load ${searchUrl}: ${searchRes.status}`)
      }
      const skeleton = await skeletonRes.json()
      const searchIndex: SpaSearchIndex = await searchRes.json()
      this.metadata = skeleton.metadata
      this.packageTree = skeleton.packageTree
      this.entries = skeleton.entries || []
      this.searchEntries = searchIndex.entries || []
      this.shardBase = shardBase || ''
      this.loaded = true
    },

    hydrateShards(shards: SpaShard[]) {
      for (const shard of shards) this.elements[shard.id] = shard
    },

    elementFor(id: string): SpaShard | null {
      return this.elements[id] || null
    },

    kindFor(id: string): string | null {
      const entry = this.entriesById[id]
      if (entry) return entry.kind
      if (this.nodesById[id]) return 'package'
      if (this.packageTree?.nodes.some((n) => n.diagramIds.includes(id))) {
        return 'diagram'
      }
      return null
    },

    shardUrlFor(id: string, kind: string): string {
      const dir = SHARD_DIRS[kind] || `${kind}s`
      return `${this.shardBase}${dir}/${id}.json`
    },

    async ensureElement(id: string): Promise<SpaShard | null> {
      const cached = this.elements[id]
      if (cached) return cached

      const kind = this.kindFor(id)
      if (!kind) return null

      const existing = inflight.get(id)
      if (existing) return existing

      const url = this.shardUrlFor(id, kind)
      const pending = fetch(url)
        .then(async (res) => {
          if (!res.ok) {
            throw new Error(`Failed to load ${url}: ${res.status}`)
          }
          const shard: SpaShard = await res.json()
          this.elements[shard.id] = shard
          return shard
        })
        .finally(() => {
          inflight.delete(id)
        })
      inflight.set(id, pending)
      return pending
    },

    async ensureElements(ids: string[]): Promise<void> {
      const queue = [...ids]
      const workers = Array.from(
        { length: Math.min(FETCH_CONCURRENCY, queue.length) },
        async () => {
          for (;;) {
            const id = queue.shift()
            if (!id) return
            try {
              await this.ensureElement(id)
            } catch {
              // leave the element missing; views render what they have
            }
          }
        },
      )
      await Promise.all(workers)
    },

    classifierEntryByName(name: string): SpaSkeletonEntry | undefined {
      return this.entries.find(
        (e) => e.qualifiedName === name || e.name === name,
      )
    },
  },
})
