<script setup lang="ts">
import { computed, watch } from 'vue'
import { useDataStore } from '../stores/dataStore'
import { useUiStore } from '../stores/uiStore'
import type { SpaClassifierPayload, SpaGeneralizationStub } from '../types'

const data = useDataStore()
const ui = useUiStore()

const clsId = computed(() => ui.currentClassId)
const cls = computed(() =>
  clsId.value ? (data.elementFor(clsId.value)?.payload as SpaClassifierPayload | undefined) ?? null : null,
)

watch(
  clsId,
  async (id) => {
    if (!id) return
    const shard = await data.ensureElement(id)
    if (!shard) return
    const parents = (shard.payload.generalizations || []).map(
      (g: SpaGeneralizationStub) => g.targetId,
    )
    await data.ensureElements(parents)
  },
  { immediate: true },
)

const definition = computed(
  () => cls.value?.annotations?.find((a) => a.kind === 'documentation')?.body || '',
)

const BASIC_TYPES = new Set([
  'String', 'Integer', 'Boolean', 'Real', 'UnlimitedNatural',
  'DateTime', 'URI', 'Any', 'Object',
])

function resolveTypeEntry(typeName?: string) {
  if (!typeName) return null
  return data.classifierEntryByName(typeName)
}

function isBasicType(typeName?: string): boolean {
  return !!typeName && BASIC_TYPES.has(typeName)
}

function entryName(id?: string): string {
  if (!id) return ''
  return data.entriesById[id]?.name || id
}

function formatCardinality(m?: [number?, number?]): string {
  if (!m) return ''
  return `${m[0] ?? 0}..${m[1] ?? '*'}`
}

function formatParameters(op: { parameters: { name?: string; typeName?: string }[] }): string {
  return op.parameters
    .map((p) => `${p.name || ''}: ${p.typeName || '?'}`)
    .join(', ')
}

function badgeType(c: SpaClassifierPayload): string {
  return (c.modelKind || 'class').toUpperCase()
}
</script>

<template>
  <div class="detail-view" v-if="cls">
    <div class="entity-header">
      <div class="entity-title">
        <h2 class="entity-name">{{ cls.qualifiedName }}</h2>
        <div class="entity-subtitle" v-if="cls.packageId">
          <a href="#" class="link-button"
             @click.prevent="ui.selectPackage(cls.packageId, data.nodesById[cls.packageId]?.name)">
            {{ data.nodesById[cls.packageId]?.name || cls.packageName || cls.packageId }}
          </a>
        </div>
      </div>
      <span class="entity-badge" :class="'badge-' + cls.modelKind">{{ badgeType(cls) }}</span>
      <span class="entity-badge badge-abstract" v-if="cls.isAbstract">abstract</span>
    </div>

    <div class="entity-metadata" v-if="cls.stereotypeRefs.length">
      <div class="metadata-item">
        <span class="metadata-label">Stereotypes</span>
        <span class="metadata-value">
          <span v-for="s in cls.stereotypeRefs" :key="s" class="stereotype-tag">&laquo;{{ s }}&raquo;</span>
        </span>
      </div>
    </div>

    <div class="entity-definition" v-if="definition">
      <div class="definition-content">{{ definition }}</div>
    </div>

    <!-- Inheritance -->
    <div class="section" v-if="cls.generalizations?.length || cls.specializations?.length">
      <h3 class="section-title">Inheritance</h3>
      <div v-if="cls.generalizations?.length" class="inheritance-group">
        <div class="inheritance-header">&#8593; Extends</div>
        <div v-for="g in cls.generalizations" :key="g.id" class="list-item clickable-row"
             @click="ui.selectClass(g.targetId, entryName(g.targetId))">
          <span class="list-item-name">{{ entryName(g.targetId) }}</span>
        </div>
      </div>
      <div v-if="cls.specializations?.length" class="inheritance-group">
        <div class="inheritance-header">&#8595; Extended by</div>
        <div v-for="g in cls.specializations" :key="g.id" class="list-item clickable-row"
             @click="ui.selectClass(g.targetId, entryName(g.targetId))">
          <span class="list-item-name">{{ entryName(g.targetId) }}</span>
        </div>
      </div>
    </div>

    <!-- Attributes -->
    <div class="section" v-if="cls.properties.length">
      <h3 class="section-title">Attributes <span class="section-count">{{ cls.properties.length }}</span></h3>
      <div class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Visibility</th>
              <th>Cardinality</th>
              <th>Modifiers</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="attr in cls.properties" :key="attr.id" class="clickable-row">
              <td>{{ attr.name }}</td>
              <td>
                <template v-if="attr.typeName">
                  <a v-if="resolveTypeEntry(attr.typeName)"
                     href="#" class="type-link"
                     @click.prevent="ui.selectClass(resolveTypeEntry(attr.typeName)!.id, resolveTypeEntry(attr.typeName)!.name)">
                    {{ attr.typeName }}
                  </a>
                  <span v-else-if="isBasicType(attr.typeName)" class="uml-basic-type">
                    {{ attr.typeName }}
                  </span>
                  <span v-else class="type-unresolved">{{ attr.typeName }}</span>
                </template>
              </td>
              <td>
                <span v-if="attr.visibility" class="visibility-badge" :data-visibility="attr.visibility">
                  {{ attr.visibility }}
                </span>
              </td>
              <td>{{ formatCardinality([attr.multiplicityLower, attr.multiplicityUpper]) }}</td>
              <td>
                <span v-if="attr.isReadonly" class="modifier-badge">readonly</span>
                <span v-if="attr.isDerived" class="modifier-badge">derived</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Operations -->
    <div class="section" v-if="cls.operations.length">
      <h3 class="section-title">Operations <span class="section-count">{{ cls.operations.length }}</span></h3>
      <div class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr><th>Name</th><th>Return</th><th>Visibility</th><th>Modifiers</th></tr>
          </thead>
          <tbody>
            <tr v-for="op in cls.operations" :key="op.id" class="clickable-row">
              <td>
                {{ op.name }}(
                <span v-if="op.parameters.length">{{ formatParameters(op) }}</span>
                )
              </td>
              <td>{{ op.returnTypeName || 'void' }}</td>
              <td>
                <span v-if="op.visibility" class="visibility-badge" :data-visibility="op.visibility">
                  {{ op.visibility }}
                </span>
              </td>
              <td>
                <span v-if="op.isStatic" class="modifier-badge">static</span>
                <span v-if="op.isAbstract" class="modifier-badge">abstract</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Associations -->
    <div class="section" v-if="cls.associations?.length">
      <h3 class="section-title">Associations <span class="section-count">{{ cls.associations.length }}</span></h3>
      <div class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr><th>Name</th><th>Target</th><th>Cardinality</th><th>Aggregation</th></tr>
          </thead>
          <tbody>
            <tr v-for="assoc in cls.associations" :key="assoc.id">
              <td>{{ assoc.name || assoc.thisEndRoleName || '' }}</td>
              <td>
                <a v-if="data.entriesById[assoc.otherEndId]" href="#" class="type-link"
                   @click.prevent="ui.selectClass(assoc.otherEndId, entryName(assoc.otherEndId))">
                  {{ entryName(assoc.otherEndId) }}
                </a>
                <span v-else>{{ assoc.otherEndId }}</span>
              </td>
              <td>{{ formatCardinality(assoc.otherEndMultiplicity) }}</td>
              <td>{{ assoc.otherEndAggregation }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Enum Literals -->
    <div class="section" v-if="cls.literals?.length">
      <h3 class="section-title">Literals <span class="section-count">{{ cls.literals.length }}</span></h3>
      <div class="item-list">
        <div v-for="lit in cls.literals" :key="lit.id" class="list-item">
          <span class="list-item-name">{{ lit.name }}</span>
          <span v-if="lit.value && lit.value !== lit.name" class="list-item-meta">{{ lit.value }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
