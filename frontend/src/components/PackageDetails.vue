<script setup lang="ts">
import { computed, watch } from 'vue'
import { useDataStore } from '../stores/dataStore'
import { useUiStore } from '../stores/uiStore'
import type { SpaPackagePayload } from '../types'

const data = useDataStore()
const ui = useUiStore()

const pkgId = computed(() => ui.currentPackageId)
const pkg = computed(() =>
  pkgId.value ? (data.elementFor(pkgId.value)?.payload as SpaPackagePayload | undefined) ?? null : null,
)

watch(
  pkgId,
  async (id) => {
    if (!id) return
    const shard = await data.ensureElement(id)
    if (!shard || ui.currentPackageId !== id) return
    const p = shard.payload
    await data.ensureElements([
      ...(p.classifierIds || []),
      ...(p.subPackageIds || []),
      ...(p.diagramIds || []),
    ])
  },
  { immediate: true },
)

function definitionOf(p: SpaPackagePayload | null): string {
  return p?.annotations?.find((a) => a.kind === 'documentation')?.body || ''
}

const subPackageIds = computed(() => pkg.value?.subPackageIds ?? [])
const diagramIds = computed(() => pkg.value?.diagramIds ?? [])
const classifierIds = computed(() => pkg.value?.classifierIds ?? [])

function pkgName(id: string): string {
  return data.nodesById[id]?.name || id
}

function diagramName(id: string): string {
  return data.elementFor(id)?.payload?.name || id
}

function entryFor(id: string) {
  return data.entriesById[id]
}

function elementFor(id: string) {
  return data.elementFor(id)?.payload
}
</script>

<template>
  <div class="detail-view" v-if="pkg">
    <div class="entity-header">
      <div class="entity-title">
        <h2 class="entity-name">{{ pkg.name }}</h2>
      </div>
      <span class="entity-badge badge-package">Package</span>
    </div>

    <div class="entity-metadata" v-if="pkg.stereotypeRefs.length">
      <div class="metadata-item">
        <span class="metadata-label">Stereotypes</span>
        <span class="metadata-value">
          <span v-for="s in pkg.stereotypeRefs" :key="s" class="stereotype-tag">&laquo;{{ s }}&raquo;</span>
        </span>
      </div>
    </div>

    <div class="entity-definition" v-if="definitionOf(pkg)">
      <div class="definition-content">{{ definitionOf(pkg) }}</div>
    </div>

    <div class="section" v-if="diagramIds.length">
      <h3 class="section-title">Diagrams <span class="section-count">{{ diagramIds.length }}</span></h3>
      <div class="item-list">
        <div v-for="diagId in diagramIds" :key="diagId"
             class="list-item clickable-row" @click="ui.selectDiagram(diagId)">
          <span class="list-item-icon">&#128202;</span>
          <span class="list-item-name">{{ diagramName(diagId) }}</span>
        </div>
      </div>
    </div>

    <div class="section" v-if="subPackageIds.length">
      <h3 class="section-title">Sub-Packages <span class="section-count">{{ subPackageIds.length }}</span></h3>
      <div class="item-list">
        <div v-for="subId in subPackageIds" :key="subId"
             class="list-item clickable-row" @click="ui.selectPackage(subId, pkgName(subId))">
          <span class="list-item-icon">&#128193;</span>
          <span class="list-item-name">{{ pkgName(subId) }}</span>
          <span class="tree-count">{{ data.nodesById[subId]?.classifierIds.length || 0 }}</span>
        </div>
      </div>
    </div>

    <div class="section" v-if="classifierIds.length">
      <h3 class="section-title">Classes <span class="section-count">{{ classifierIds.length }}</span></h3>
      <div class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Stereotypes</th>
              <th>Attrs</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="clsId in classifierIds" :key="clsId" class="clickable-row"
                @click="ui.selectClass(clsId, entryFor(clsId)?.name)">
              <td>{{ entryFor(clsId)?.name || elementFor(clsId)?.name || clsId }}</td>
              <td><span class="entity-badge" :class="'badge-' + (entryFor(clsId)?.kind || 'class')">{{ entryFor(clsId)?.kind || 'class' }}</span></td>
              <td>
                <span v-for="s in (elementFor(clsId)?.stereotypeRefs || [])" :key="s"
                      class="stereotype-tag">&laquo;{{ s }}&raquo;</span>
              </td>
              <td>{{ elementFor(clsId)?.properties?.length || 0 }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="empty-state" v-if="!classifierIds.length && !subPackageIds.length && !diagramIds.length">
      <p>This package is empty.</p>
    </div>
  </div>
</template>
