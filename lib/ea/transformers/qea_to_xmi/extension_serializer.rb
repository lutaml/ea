# frozen_string_literal: true

module Ea
  module Transformers
    module QeaToXmi
      # Serializes the EA-specific content of `<xmi:Extension>`.
      #
      # The xmi gem models the structural XMI tree (model, packages,
      # classes, attributes) but does not represent EA's per-element
      # extension metadata. This class produces the inner XML for the
      # `<xmi:Extension>` element as three sibling sections:
      #
      #   <elements>   — one <element> per package/classifier, carrying
      #                  <model>, <properties documentation="...">,
      #                  <style appearance="..."> and nested <tags>.
      #   <connectors> — one <connector> per relationship, with
      #                  source/target <model> blocks.
      #   <diagrams>   — one <diagram> per diagram, with placed
      #                  <element> children referencing subjects.
      #
      # The Transformer injects this string into the serialized XMI's
      # empty `<xmi:Extension>` placeholder.
      #
      # Sparx XMI is the canonical shape; the xmi gem's parser does not
      # model these sections, so output containing them is not
      # round-trippable through `Xmi::Sparx::Root.parse_xml`.
      class ExtensionSerializer
        def initialize(database, context)
          @database = database
          @context = context
        end

        # @return [String] inner XML for <xmi:Extension>; empty if no
        #   elements/connectors/diagrams to emit.
        def call
          sections = [
            build_elements_section,
            build_connectors_section,
            build_primitivetypes_section,
            build_diagrams_section
          ].reject(&:empty?)
          sections.join("\n")
        end

        private

        # ---- <elements> section -----------------------------------------

        def build_elements_section
          entries = element_entries
          return "" if entries.empty?

          "\t\t<elements>\n#{entries.join("\n")}\n\t\t</elements>"
        end

        # One <element> block per package and per classifier object.
        # Notes/Text/ProxyConnector objects are skipped — they have no
        # standalone representation in the extension's <elements> list.
        def element_entries
          packages = @database.collections[:packages] || []
          objects = @database.collections[:objects] || []
          package_entries = packages.map { |pkg| package_element_xml(pkg) }
          object_entries = objects.filter_map { |obj| object_element_xml(obj) }
          (package_entries + object_entries).compact
        end

        def package_element_xml(pkg)
          idref = @context.xmi_id_for(pkg, prefix: "EAPK")
          return nil unless idref

          name = pkg.name.to_s
          scope = "public"
          lines = [
            %(\t\t<element xmi:idref="#{idref}" xmi:type="uml:Package" name="#{escape(name)}" scope="#{scope}">),
            model_for_package(pkg),
            properties_for(record_documentation(pkg.notes), stype: "Package", scope: scope),
            style_for_package(pkg),
            tags_block_for(pkg.ea_guid),
            "\t\t</element>"
          ]
          lines.join("\n")
        end

        def object_element_xml(obj)
          return nil if skip_object?(obj)

          idref = @context.xmi_id_for(obj)
          return nil unless idref

          uml_type = uml_type_for(obj)
          name = obj.name.to_s
          scope = (obj.scope || "Public").downcase
          lines = [
            %(\t\t<element xmi:idref="#{idref}" xmi:type="#{uml_type}" name="#{escape(name)}" scope="#{scope}">),
            model_for_object(obj),
            properties_for(record_documentation(obj.note), stype: obj.object_type, scope: scope,
                                                           is_abstract: obj.abstract?),
            style_for_object(obj),
            tags_block_for(obj.ea_guid),
            xrefs_xml("\t\t\t", obj.ea_guid, "element property"),
            attributes_block_for(obj),
            operations_block_for(obj),
            "\t\t</element>"
          ]
          lines.join("\n")
        end

        # EA object types that are diagram-only annotations or internal
        # plumbing — they don't get a standalone <element> entry.
        SKIP_OBJECT_TYPES = %w[Note Text ProxyConnector Boundary].freeze

        def skip_object?(obj)
          obj.object_type.nil? || SKIP_OBJECT_TYPES.include?(obj.object_type)
        end

        # OCP registry: EA object type → UML XMI type.
        # Adding a new mapping = adding one entry, not editing a
        # case/when branch.
        UML_TYPE_FOR = {
          "Class" => "uml:Class",
          "Interface" => "uml:Interface",
          "Enumeration" => "uml:Enumeration",
          "DataType" => "uml:DataType",
          "PrimitiveType" => "uml:PrimitiveType",
          "Object" => "uml:Object",
          "Signal" => "uml:Signal",
          "Package" => "uml:Package",
          "Association" => "uml:Association"
        }.freeze

        def uml_type_for(obj)
          UML_TYPE_FOR[obj.object_type] || obj.object_type.to_s
        end

        # ---- <model> / <properties> / <style> ---------------------------

        def model_for_package(pkg)
          parent = parent_package_ref(pkg)
          owner = parent
          attrs = [
            %(package2="#{@context.xmi_id_for(pkg)}")
          ]
          attrs << %(package="#{parent}") if parent
          attrs << %(owner="#{owner}") if owner
          attrs << %(tpos="#{pkg.tpos}") if pkg.tpos
          attrs << %(ea_localid="#{pkg.package_id}")
          attrs << %(ea_eleType="package")
          "\t\t\t<model #{attrs.join(" ")}/>"
        end

        def model_for_object(obj)
          pkg_ref = owner_package_ref(obj)
          attrs = []
          attrs << %(package="#{pkg_ref}") if pkg_ref
          attrs << %(tpos="#{obj.tpos}") if obj.tpos
          attrs << %(ea_localid="#{obj.ea_object_id}")
          attrs << %(ea_eleType="element")
          "\t\t\t<model #{attrs.join(" ")}/>"
        end

        def properties_for(documentation, stype:, scope:, is_abstract: nil)
          attrs = []
          attrs << %(documentation="#{escape(documentation)}") unless documentation.nil? || documentation.empty?
          attrs << %(isSpecification="false")
          attrs << %(sType="#{stype}")
          attrs << %(nType="0")
          attrs << %(scope="#{scope}")
          attrs << %(isAbstract="#{is_abstract ? "true" : "false"}")
          "\t\t\t<properties #{attrs.join(" ")}/>"
        end

        def style_for_package(_pkg)
          # Packages in t_package have no style column; EA emits a
          # default style block for them.
          default = "BackColor=-1;BorderColor=-1;BorderWidth=-1;" \
                    "FontColor=-1;VSwimLanes=1;HSwimLanes=1;BorderStyle=0;"
          %(\t\t\t<style appearance="#{escape(default)}"/>)
        end

        def style_for_object(obj)
          appearance = obj.style && obj.style.empty? ? default_object_style : obj.style
          %(\t\t\t<style appearance="#{escape(appearance.to_s)}"/>)
        end

        def default_object_style
          "BackColor=-1;BorderColor=-1;BorderWidth=-1;" \
            "FontColor=-1;VSwimLanes=1;HSwimLanes=1;BorderStyle=0;"
        end

        # ---- <tags> -----------------------------------------------------

        # Tags section for one model element. Looks up tagged values
        # whose ElementID matches the given GUID. Returns an empty
        # <tags/> when there are none — matches EA's output shape.
        def tags_block_for(element_guid)
          tags = tagged_values_for(element_guid)
          if tags.empty?
            "\t\t\t<tags/>"
          else
            inner = tags.map { |tv| tag_xml(tv) }.join("\n")
            "\t\t\t<tags>\n#{inner}\n\t\t\t</tags>"
          end
        end

        def tag_xml(tv)
          tag_id = GuidFormat.ea_guid_to_xmi_id(tv.property_id)
          tag_name = tv.tag_name.to_s
          value = tv.parsed_value
          model_element = element_ref_for_tag(tv)
          attrs = [%(xmi:id="#{tag_id}"), %(name="#{escape(tag_name)}")]
          attrs << %(value="#{escape(value)}") unless value.nil? || value.empty?
          attrs << %(modelElement="#{model_element}") if model_element
          "\t\t\t\t<tag #{attrs.join(" ")}/>"
        end

        def tagged_values_for(element_guid)
          return [] unless element_guid

          @database.tagged_values_for_element(element_guid)
        end

        def element_ref_for_tag(tv)
          return nil unless tv.element_id

          GuidFormat.ea_guid_to_xmi_id(tv.element_id)
        end

        # ---- <attributes> block -----------------------------------------

        # Classifier types that own attributes in their <attributes>
        # extension block. Enumerations use <ownedLiteral> instead;
        # InstanceSpecifications have no attributes.
        ATTRIBUTE_OWNERS = %w[Class Interface DataType PrimitiveType].freeze

        def attributes_block_for(obj)
          return "" unless ATTRIBUTE_OWNERS.include?(obj.object_type)

          attrs = @context.attributes_for(obj.ea_object_id)
          return "" if attrs.empty?

          inner = attrs.map { |attr| attribute_xml(attr) }.join("\n")
          "\t\t\t<attributes>\n#{inner}\n\t\t\t</attributes>"
        end

        def attribute_xml(attr)
          idref = @context.xmi_id_for(attr)
          scope = attribute_scope(attr)
          lines = [
            %(\t\t\t\t<attribute xmi:idref="#{idref}" name="#{escape(attr.name.to_s)}" scope="#{scope}">),
            "\t\t\t\t\t<initial/>",
            documentation_element(attr.notes),
            "\t\t\t\t\t<model ea_localid=\"#{attr.id}\" ea_guid=\"#{escape(attr.ea_guid.to_s)}\"/>",
            attribute_properties(attr),
            "\t\t\t\t\t<coords ordered=\"0\" scale=\"0\"/>",
            "\t\t\t\t\t<containment containment=\"Not Specified\" position=\"#{attr.pos || 0}\"/>",
            "\t\t\t\t\t<stereotype/>",
            bounds_xml(attr),
            "\t\t\t\t\t<options/>",
            "\t\t\t\t\t<style/>",
            %(\t\t\t\t\t<styleex value="#{escape(attr.styleex.to_s)}"/>),
            "\t\t\t\t\t<tags/>",
            xrefs_xml("\t\t\t\t\t", attr.ea_guid, "attribute property"),
            "\t\t\t\t</attribute>"
          ]
          lines.join("\n")
        end

        # Shares the transformer's pair rule so the extension block and
        # the UML tree can never report different multiplicities.
        def bounds_xml(attr)
          bounds = Cardinality.attribute_bounds(attr.lowerbound, attr.upperbound)
          %(\t\t\t\t\t<bounds lower="#{escape(bounds[:lower])}" upper="#{escape(bounds[:upper])}"/>)
        end

        def attribute_scope(attr)
          (attr.scope || "Public").downcase.capitalize
        end

        def attribute_properties(attr)
          attrs = [
            %(type="#{escape(attr.type.to_s)}"),
            %(derived="#{derived_flag(attr)}"),
            %(precision="#{attr.precision || 0}"),
            %(collection="false"),
            %(length="#{attr.length || 0}"),
            %(static="#{attr.isstatic || 0}"),
            %(duplicates="#{attr.allowduplicates || 0}"),
            %(changeability="changeable")
          ]
          "\t\t\t\t\t<properties #{attrs.join(" ")}/>"
        end

        def derived_flag(attr)
          attr.derived == "1" ? "1" : "0"
        end

        # ---- <operations> block -----------------------------------------

        OPERATION_OWNERS = %w[Class Interface DataType PrimitiveType].freeze

        def operations_block_for(obj)
          return "" unless OPERATION_OWNERS.include?(obj.object_type)

          ops = @context.operations_for(obj.ea_object_id)
          return "" if ops.empty?

          inner = ops.map { |op| operation_xml(op) }.join("\n")
          "\t\t\t\t<operations>\n#{inner}\n\t\t\t\t</operations>"
        end

        def operation_xml(op)
          idref = @context.xmi_id_for(op)
          scope = operation_scope(op)
          lines = [
            %(\t\t\t\t<operation xmi:idref="#{idref}" name="#{escape(op.name.to_s)}" scope="#{scope}">),
            %(\t\t\t\t\t<properties position="#{op.pos || 0}"/>),
            "\t\t\t\t\t<stereotype/>",
            "\t\t\t\t\t<model ea_guid=\"#{escape(op.ea_guid.to_s)}\" ea_localid=\"#{op.operationid}\"/>",
            operation_type(op),
            "\t\t\t\t\t<behaviour/>",
            "\t\t\t\t\t<code/>",
            "\t\t\t\t\t<style/>",
            "\t\t\t\t\t<styleex/>",
            *operation_tail(op)
          ]
          lines.join("\n")
        end

        def operation_tail(op)
          [documentation_element(op.notes),
           "\t\t\t\t\t<tags/>",
           parameters_block_for(op),
           xrefs_xml("\t\t\t\t\t", op.ea_guid, "operation property"),
           "\t\t\t\t</operation>"]
        end

        def operation_scope(op)
          (op.scope || "Public").downcase.capitalize
        end

        def operation_type(op)
          attrs = [
            %(type="#{escape(op.type.to_s)}"),
            %(const="false"),
            %(static="#{op.isstatic || 0}"),
            %(isAbstract="#{op.abstract || 0}"),
            %(synchronised="0"),
            %(concurrency="#{escape((op.concurrency || "Sequential").to_s)}"),
            %(returnarray="0"),
            %(pure="#{op.pure || 0}"),
            %(isQuery="#{op.pure && op.pure != 0 ? "true" : "false"}")
          ]
          "\t\t\t\t\t<type #{attrs.join(" ")}/>"
        end

        def parameters_block_for(op)
          entries = [return_parameter_xml(op), *declared_parameters_xml(op)].compact
          return "" if entries.empty?

          "\t\t\t\t\t<parameters>\n#{entries.join("\n")}\n\t\t\t\t\t</parameters>"
        end

        def declared_parameters_xml(op)
          @context.params_for_operation(op.operationid)
                  .reject(&:return?)
                  .map { |param| parameter_xml(param) }
        end

        # The trailing children of a synthesized return parameter —
        # all empty, in EA's order.
        RETURN_PARAMETER_TAIL = ["\t\t\t\t\t\t\t<style/>",
                                 "\t\t\t\t\t\t\t<styleex/>",
                                 "\t\t\t\t\t\t\t<documentation/>",
                                 "\t\t\t\t\t\t\t<tags/>",
                                 "\t\t\t\t\t\t\t<xrefs/>"].freeze

        # EA lists the return first, as a synthesized parameter with no
        # t_operationparams row behind it. Both its idref and its
        # ea_guid come from the operation's own id via {GuidFormat}, so
        # the two agree by construction — an untyped operation has no
        # return to describe, and one whose nullable t_operation.ea_guid
        # is blank has nothing to derive the ids from.
        def return_parameter_xml(operation)
          return nil if PrimitiveTypes.normalize_name(operation.type).empty?
          return nil unless @context.identifiable?(operation)

          return_id = GuidFormat.return_parameter_xmi_id(@context.xmi_id_for(operation))
          [%(\t\t\t\t\t\t<parameter xmi:idref="#{return_id}" visibility="public">),
           %(\t\t\t\t\t\t\t<properties pos="0" type="#{escape(operation.type.to_s)}" const="false" ) +
             %(ea_guid="#{GuidFormat.xmi_id_to_ea_guid(return_id)}"/>),
           *RETURN_PARAMETER_TAIL,
           "\t\t\t\t\t\t</parameter>"].join("\n")
        end

        def parameter_xml(param)
          idref = @context.xmi_id_for(param)
          lines = [
            %(\t\t\t\t\t\t<parameter xmi:idref="#{idref}" visibility="public">),
            %(\t\t\t\t\t\t\t<properties pos="#{param.pos || 0}" type="#{escape(param.type.to_s)}" const="false" ea_guid="#{escape(param.ea_guid.to_s)}"/>),
            "\t\t\t\t\t\t\t<style/>",
            "\t\t\t\t\t\t\t<styleex/>",
            documentation_element(param.notes),
            "\t\t\t\t\t\t\t<tags/>",
            "\t\t\t\t\t\t\t<xrefs/>",
            "\t\t\t\t\t\t</parameter>"
          ]
          lines.join("\n")
        end

        # Emits a <documentation value="..."/> element for attribute/
        # operation/parameter sub-blocks. Empty element when there's
        # no note content (matches EA's output for blank notes).
        def documentation_element(note)
          if note.nil? || note.empty?
            "\t\t\t\t\t<documentation/>"
          else
            %(\t\t\t\t\t<documentation value="#{escape(note)}"/>)
          end
        end

        # ---- <connectors> section --------------------------------------

        def build_connectors_section
          connectors = @database.collections[:connectors] || []
          return "" if connectors.empty?

          inner = connectors.filter_map { |conn| connector_xml(conn) }.join("\n")
          return "" if inner.empty?

          "\t\t<connectors>\n#{inner}\n\t\t</connectors>"
        end

        def connector_xml(conn)
          return nil unless conn.ea_guid

          connector_id = @context.xmi_id_for(conn)
          source_obj = @database.find_object(conn.start_object_id)
          target_obj = @database.find_object(conn.end_object_id)
          return nil unless source_obj && target_obj

          name_attr = conn.name ? %( name="#{escape(conn.name)}") : ""
          inner = end_xml(conn, source_obj, "source") + end_xml(conn, target_obj, "target") + connector_body_xml(conn)
          %(\t\t<connector xmi:idref="#{connector_id}"#{name_attr}>\n#{inner}\t\t</connector>)
        end

        END_XREF_TYPE = {
          "source" => "connectorSrcEnd property",
          "target" => "connectorDestEnd property"
        }.freeze

        def end_xml(conn, obj, kind)
          xmi_id = @context.xmi_id_for(obj)
          lines = [
            "\t\t\t<#{kind} xmi:idref=\"#{xmi_id}\">",
            "\t\t\t\t<model ea_localid=\"#{obj.ea_object_id}\" " \
              "type=\"#{obj.object_type}\" name=\"#{escape(obj.name.to_s)}\"/>",
            "\t\t\t\t<role visibility=\"Public\" targetScope=\"instance\"/>",
            "\t\t\t\t<type aggregation=\"none\" containment=\"Unspecified\"/>",
            "\t\t\t\t<constraints/>",
            "\t\t\t\t<modifiers isOrdered=\"false\" changeable=\"none\" isNavigable=\"false\"/>",
            "\t\t\t\t<style value=\"Union=0;Derived=0;AllowDuplicates=0;Owned=0;Navigable=Unspecified;\"/>",
            "\t\t\t\t<documentation/>",
            xrefs_xml("\t\t\t\t", conn.ea_guid, END_XREF_TYPE.fetch(kind)),
            "\t\t\t\t<tags/>",
            "\t\t\t</#{kind}>"
          ]
          "#{lines.join("\n")}\n"
        end

        # Connector-level body (after source/target): model, properties,
        # documentation, appearance, style, tags. Matches the reference
        # EA output shape.
        def connector_body_xml(conn)
          ea_type = conn.connector_type || "Association"
          lines = [
            "\t\t\t<model ea_localid=\"#{conn.connector_id}\"/>",
            %(\t\t\t<properties ea_type="#{escape(ea_type)}" direction="Unspecified"/>),
            "\t\t\t<modifiers isRoot=\"false\" isLeaf=\"false\"/>",
            "\t\t\t<parameterSubstitutions/>",
            "\t\t\t<documentation/>",
            "\t\t\t<appearance linemode=\"3\" linecolor=\"-1\" linewidth=\"0\" " \
              "seqno=\"0\" headStyle=\"0\" lineStyle=\"0\"/>",
            "\t\t\t<extendedProperties virtualInheritance=\"0\"/>",
            "\t\t\t<style/>",
            xrefs_xml("\t\t\t", conn.ea_guid, "connector property"),
            "\t\t\t<tags/>"
          ]
          "#{lines.join("\n")}\n"
        end

        # ---- <xrefs> ----------------------------------------------------

        # EA renders t_xref rows as a $XREFPROP mini-language string in
        # a single value attribute. Derived from the reference exports:
        # token order $XID $NAM $TYP $VIS [$BEH] $PAR $DES $CLT [$SUP]
        # $ENDXREF; — $BEH only when Behavior is non-blank. A blank
        # Supplier renders as "<none>" except on "connector property"
        # rows, where EA omits the token entirely. "diagram properties"
        # rows are never rendered (reference diagrams keep <xrefs/>).
        def xrefs_xml(indent, ea_guid, type)
          rows = @database.xrefs_for_client(ea_guid.to_s)
                          .select { |xref| xref.xref_type == type }
          return "#{indent}<xrefs/>" if rows.empty?

          value = rows.map { |xref| xref_value(xref) }.join
          %(#{indent}<xrefs value="#{escape(value)}"/>)
        end

        def xref_value(xref)
          head = "$XREFPROP=$XID=#{xref.xref_id}$XID;$NAM=#{xref.name}$NAM;" \
                 "$TYP=#{xref.xref_type}$TYP;$VIS=#{xref.visibility}$VIS;"
          beh = xref.behavior.to_s.empty? ? "" : "$BEH=#{xref.behavior}$BEH;"
          tail = "$PAR=#{xref.partition}$PAR;$DES=#{xref.description}$DES;" \
                 "$CLT=#{xref.client}$CLT;#{supplier_token(xref)}$ENDXREF;"
          "#{head}#{beh}#{tail}"
        end

        def supplier_token(xref)
          return "$SUP=#{xref.supplier}$SUP;" unless xref.supplier.to_s.empty?
          return "" if xref.xref_type == "connector property"

          "$SUP=<none>$SUP;"
        end

        # ---- <primitivetypes> section ----------------------------------

        # EA nests every synthesized EAnone_ PrimitiveType definition
        # under a fixed two-package hierarchy inside the Extension.
        def build_primitivetypes_section
          names = PrimitiveTypes.unresolved_names(@database)
          return "" if names.empty?

          ["\t\t<primitivetypes>",
           primitive_package("\t\t\t", "EAPrimitiveTypesPackage", "EA_PrimitiveTypes_Package"),
           primitive_package("\t\t\t\t", "EAnoneTypesPackage", "EA_none_Types_Package"),
           *names.map { |name| primitive_definition(name) },
           "\t\t\t\t</packagedElement>",
           "\t\t\t</packagedElement>",
           "\t\t</primitivetypes>"].join("\n")
        end

        def primitive_package(indent, id, name)
          %(#{indent}<packagedElement xmi:type="uml:Package" xmi:id="#{id}" name="#{name}">)
        end

        def primitive_definition(name)
          "\t\t\t\t\t<packagedElement xmi:type=\"uml:PrimitiveType\" " \
            "xmi:id=\"#{escape(PrimitiveTypes.definition_id(name))}\" name=\"#{escape(name)}\"/>"
        end

        # ---- <diagrams> section ----------------------------------------

        def build_diagrams_section
          diagrams = @database.collections[:diagrams] || []
          return "" if diagrams.empty?

          inner = diagrams.filter_map { |dgm| diagram_xml(dgm) }.join("\n")
          return "" if inner.empty?

          "\t\t<diagrams>\n#{inner}\n\t\t</diagrams>"
        end

        def diagram_xml(dgm)
          return nil unless dgm.ea_guid

          diagram_id = @context.xmi_id_for(dgm)
          pkg_guid = package_guid_for(dgm)
          pkg_ref = pkg_guid ? GuidFormat.ea_guid_to_xmi_id(pkg_guid, prefix: "EAPK") : ""
          elements_xml = diagram_elements_xml(dgm)
          lines = [
            "\t\t<diagram xmi:id=\"#{diagram_id}\">",
            "\t\t\t<model package=\"#{pkg_ref}\" localID=\"#{dgm.diagram_id}\" owner=\"#{pkg_ref}\"/>",
            "\t\t\t<properties name=\"#{escape(dgm.name.to_s)}\" type=\"#{escape(dgm.diagram_type.to_s)}\"/>",
            elements_xml,
            "\t\t</diagram>"
          ]
          lines.join("\n")
        end

        # EA emits object placements (t_diagramobjects, ordered by
        # Sequence) followed by connector entries (t_diagramlinks).
        # Derived from examples/exports/basic/model.xml:
        #   placement: geometry="Left=..;Top=..;Right=..;Bottom=..;
        #     imgL=..;imgT=..;imgR=..;imgB=..;" from the Rect* columns
        #     (Top/Bottom sign-flipped; img* at fixed +25/+30 offsets),
        #     seqno=Sequence, style=ObjectStyle verbatim.
        #   connector: subject is the CONNECTOR's EAID, geometry is the
        #     link's Geometry plus "Path=<path>;", style is the link's
        #     Style plus "Hidden=<hidden>;".
        def diagram_elements_xml(dgm)
          placements = @database.diagram_objects_for(dgm.diagram_id)
                                .sort_by { |placement| placement_order(placement) }
                                .filter_map { |placement| object_placement_xml(placement) }
          links = @database.diagram_links_for(dgm.diagram_id)
                           .filter_map { |link| connector_entry_xml(link) }
          inner = (placements + links).join("\n")
          return "\t\t\t<elements/>" if inner.empty?

          "\t\t\t<elements>\n#{inner}\n\t\t\t</elements>"
        end

        IMG_OFFSET_X = 25
        IMG_OFFSET_Y = 30

        def object_placement_xml(placement)
          obj = @database.find_object(placement.ea_object_id)
          return nil unless obj

          "\t\t\t\t<element geometry=\"#{placement_geometry(placement)}\" " \
            "subject=\"#{escape(@context.xmi_id_for(obj).to_s)}\" " \
            "seqno=\"#{placement.sequence.to_i}\" style=\"#{escape(placement.objectstyle.to_s)}\"/>"
        end

        # Sequence is nullable with DEFAULT 0 — nil sorts as 0, ties
        # broken stably by instance id.
        def placement_order(placement)
          [placement.sequence.to_i, placement.instance_id.to_i]
        end

        # Rect columns are nullable with DEFAULT 0 — coerce nil to 0.
        def placement_geometry(placement)
          left = placement.rectleft.to_i
          top = -placement.recttop.to_i
          right = placement.rectright.to_i
          bottom = -placement.rectbottom.to_i
          "Left=#{left};Top=#{top};Right=#{right};Bottom=#{bottom};" \
            "imgL=#{left + IMG_OFFSET_X};imgT=#{top + IMG_OFFSET_Y};" \
            "imgR=#{right + IMG_OFFSET_X};imgB=#{bottom + IMG_OFFSET_Y};"
        end

        def connector_entry_xml(link)
          conn = @database.find_connector(link.connectorid)
          return nil unless conn

          # EA rewrites the Path waypoints' ";" separators to "$" and
          # terminates with one ";" (reference: Path=165:-230$371:-230$;).
          geometry = "#{style_fragment(link.geometry)}Path=#{link.path.to_s.tr(";", "$")};"
          style = "#{style_fragment(link.style)}Hidden=#{link.hidden};"
          "\t\t\t\t<element geometry=\"#{escape(geometry)}\" " \
            "subject=\"#{escape(@context.xmi_id_for(conn).to_s)}\" style=\"#{escape(style)}\"/>"
        end

        # Real rows (plateau model) can lack the trailing ";" — append
        # exactly one so concatenated tokens never fuse.
        def style_fragment(text)
          value = text.to_s
          return "" if value.empty?

          value.end_with?(";") ? value : "#{value};"
        end

        # ---- helpers ----------------------------------------------------

        def parent_package_ref(pkg)
          return nil unless pkg.parent_id

          parent = @database.find_package(pkg.parent_id)
          parent ? GuidFormat.ea_guid_to_xmi_id(parent.ea_guid, prefix: "EAPK") : nil
        end

        def owner_package_ref(obj)
          return nil unless obj.package_id

          pkg = @database.find_package(obj.package_id)
          pkg ? GuidFormat.ea_guid_to_xmi_id(pkg.ea_guid, prefix: "EAPK") : nil
        end

        def package_guid_for(dgm)
          pkg = @database.find_package(dgm.package_id)
          pkg&.ea_guid || dgm.ea_guid
        end

        # Returns the documentation string for a record. Package notes
        # and object notes come from different columns; both flow
        # through here as the <properties documentation="..."> value.
        def record_documentation(note)
          note.nil? || note.empty? ? nil : note
        end

        def escape(text)
          XmlEscape.call(text)
        end
      end
    end
  end
end
