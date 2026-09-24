<script setup lang="ts">
import { computed } from 'vue'
import { useDataStore } from '../stores/dataStore'
import { useUiStore } from '../stores/uiStore'

const data = useDataStore()
const ui = useUiStore()

const resultsByKind = computed(() => {
  const groups: Record<string, typeof data.searchEntries> = {}
  for (const entry of data.searchEntries) {
    ;(groups[entry.kind] ??= []).push(entry)
  }
  return groups
})

function isClickable(kind: string): boolean {
  return kind !== 'property'
}

function open(entry: { id: string; kind: string; name: string }) {
  if (!isClickable(entry.kind)) return
  if (entry.kind === 'package') {
    ui.selectPackage(entry.id, entry.name)
  } else {
    ui.selectClass(entry.id, entry.name)
  }
}
</script>

<template>
  <div class="detail-view">
    <div class="entity-header">
      <div class="entity-title">
        <h2 class="entity-name">Search Results</h2>
      </div>
    </div>
    <div v-for="(entries, kind) in resultsByKind" :key="kind" class="section">
      <h3 class="section-title">{{ kind }}s <span class="section-count">{{ entries.length }}</span></h3>
      <div class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr><th>Name</th><th>Package</th><th>Type</th></tr>
          </thead>
          <tbody>
            <tr v-for="entry in entries" :key="entry.id" class="data-row"
                :class="{ 'clickable-row': isClickable(entry.kind) }"
                @click="open(entry)">
              <td>{{ entry.name }}</td>
              <td>{{ entry.package }}</td>
              <td><span class="entity-badge" :class="'badge-' + entry.kind">{{ entry.kind }}</span></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div class="empty-state" v-if="!data.searchEntries.length">
      <p>No results found.</p>
    </div>
  </div>
</template>
