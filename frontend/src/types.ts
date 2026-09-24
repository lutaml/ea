export interface SpaStatistics {
  packages: number
  classes: number
  attributes: number
  operations: number
  associations: number
  diagrams: number
}

export interface SpaLogoVariant {
  path?: string
  url?: string
}

export interface SpaLogoConfig {
  light: SpaLogoVariant
  dark: SpaLogoVariant
}

export interface SpaLogos {
  square?: SpaLogoConfig
  long?: SpaLogoConfig
}

export interface SpaAppearance {
  logos?: SpaLogos
}

export interface SpaMetadata {
  id?: string
  title?: string
  description?: string
  version?: string
  generated?: string
  generator?: string
  createdDate?: string
  modifiedDate?: string
  sourceFormat?: string
  sourceTool?: string
  sourcePath?: string
  appearance?: SpaAppearance
  statistics?: SpaStatistics
}

export interface SpaPackageTreeNode {
  id: string
  name: string
  parentId?: string
  childIds: string[]
  classifierIds: string[]
  diagramIds: string[]
}

export interface SpaPackageTree {
  rootIds: string[]
  nodes: SpaPackageTreeNode[]
}

export interface SpaSkeletonEntry {
  id: string
  name: string
  kind: string
  packageId?: string
  qualifiedName?: string
  shardUrl: string
}

export interface SpaShard {
  id: string
  kind: string
  payload: any
}

export interface SpaSearchEntry {
  id: string
  kind: string
  name: string
  qualifiedName: string
  package: string
  content: string
  boost?: number
}

export interface SpaSearchIndex {
  version: string
  fields: string[]
  entries: SpaSearchEntry[]
}

export interface SpaAnnotation {
  id: string
  kind: string
  body?: string
}

export interface SpaPropertyPayload {
  id: string
  name: string
  ownerId: string
  typeName?: string
  qualifiedName?: string
  multiplicityLower?: number
  multiplicityUpper?: number
  isDerived: boolean
  isReadonly: boolean
  visibility?: string
  stereotypeRefs: string[]
  annotations: SpaAnnotation[]
}

export interface SpaParameterPayload {
  name?: string
  direction?: string
  typeName?: string
  multiplicityLower?: number
  multiplicityUpper?: number
  defaultValue?: string
}

export interface SpaOperationPayload {
  id: string
  name: string
  ownerId: string
  qualifiedName?: string
  returnTypeName?: string
  isStatic: boolean
  isAbstract: boolean
  visibility?: string
  parameters: SpaParameterPayload[]
  stereotypeRefs: string[]
  annotations: SpaAnnotation[]
}

export interface SpaGeneralizationStub {
  id: string
  targetId: string
}

export interface SpaAssociationStub {
  id: string
  name?: string
  sourceId: string
  targetId: string
  thisEndRoleName?: string
  otherEndRoleName?: string
  otherEndId: string
  otherEndMultiplicity?: [number?, number?]
  otherEndAggregation?: string
}

export interface SpaEnumerationLiteralPayload {
  id: string
  name: string
  value?: string
  ordinal?: number
}

export interface SpaClassifierPayload {
  id: string
  name: string
  qualifiedName: string
  packageId: string
  packageName?: string
  isAbstract: boolean
  visibility?: string
  modelKind: string
  properties: SpaPropertyPayload[]
  operations: SpaOperationPayload[]
  stereotypeRefs: string[]
  taggedValues: any[]
  constraints: any[]
  annotations: SpaAnnotation[]
  literals?: SpaEnumerationLiteralPayload[]
  generalizations?: SpaGeneralizationStub[]
  specializations?: SpaGeneralizationStub[]
  associations?: SpaAssociationStub[]
}

export interface SpaPackagePayload {
  id: string
  name: string
  parentId?: string
  subPackageIds: string[]
  classifierIds: string[]
  diagramIds: string[]
  stereotypeRefs: string[]
  taggedValues: any[]
  annotations: SpaAnnotation[]
}

export interface SpaDiagramPayload {
  id: string
  name: string
  packageId?: string
  diagramType?: string
  elements: any[]
  connectors: any[]
  annotations: SpaAnnotation[]
  svg?: string
}

export interface SpaViewExtras {
  ui?: Record<string, any>
  appearance?: SpaAppearance
  diagrams?: { enabled?: boolean }
}

export interface SpaSkeleton {
  metadata: SpaMetadata
  packageTree: SpaPackageTree
  entries: SpaSkeletonEntry[]
  viewExtras?: SpaViewExtras
}

export interface SpaData extends SpaSkeleton {
  searchIndex: SpaSearchIndex
  shards: SpaShard[]
}
