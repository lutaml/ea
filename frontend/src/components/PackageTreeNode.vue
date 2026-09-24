<script setup lang="ts">
import { computed } from 'vue'
import { useDataStore } from '../stores/dataStore'
import { useUiStore } from '../stores/uiStore'

const props = defineProps<{ nodeId: string }>()
const data = useDataStore()
const ui = useUiStore()

const node = computed(() => data.nodesById[props.nodeId])
const isExpanded = computed(() => ui.expandedNodes.has(props.nodeId))
const isSelected = computed(() =>
  ui.currentView === 'package' && ui.currentPackageId === props.nodeId,
)
const children = computed(() => node.value?.childIds ?? [])
const childNodes = computed(() =>
  children.value.map((id) => data.nodesById[id]).filter((n) => !!n),
)
const classEntries = computed(() =>
  (node.value?.classifierIds ?? [])
    .map((id) => data.entriesById[id])
    .filter((e) => !!e),
)
const classCount = computed(() => node.value?.classifierIds.length ?? 0)

function toggle() {
  ui.toggleNode(props.nodeId)
}

function select() {
  ui.selectPackage(props.nodeId, node.value?.name)
}
</script>

<template>
  <div class="tree-node" v-if="node">
    <div class="tree-node-content" :class="{ selected: isSelected }">
      <button class="tree-toggle" v-if="children.length || classEntries.length" @click.stop="toggle">
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none" :class="{ expanded: isExpanded }">
          <path d="M4 3l3 3-3 3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>
      <span class="tree-toggle-placeholder" v-else></span>

      <span class="tree-icon" @click="select" style="cursor: pointer;">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
          <path d="M2 6L8 2L14 6V13C14 13.5 13.5 14 13 14H3C2.5 14 2 13.5 2 13V6Z" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </span>

      <span class="tree-label-group" @click="select">
        <span class="tree-label">{{ node.name }}</span>
      </span>

      <span class="tree-count" v-if="classCount">{{ classCount }}</span>
    </div>

    <div class="tree-children" v-if="isExpanded">
      <PackageTreeNode v-for="child in childNodes" :key="child.id" :node-id="child.id" />

      <div v-for="entry in classEntries" :key="entry.id"
           class="tree-item" :class="{ selected: ui.currentClassId === entry.id }"
           @click="ui.selectClass(entry.id, entry.name)">
        <span class="badge badge-class">{{ entry.kind.charAt(0).toUpperCase() }}</span>
        <span class="tree-item-label">{{ entry.name }}</span>
      </div>
    </div>
  </div>
</template>
