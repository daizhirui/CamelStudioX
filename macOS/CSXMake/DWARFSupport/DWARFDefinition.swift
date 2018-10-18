//
//  DWARFDefinition.swift
//  CSXToolchains
//
//  Created by Zhirui Dai on 2018/10/11.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

class DWARF {
    
    /**
     Debugging information entry is written in short as DIE.
     The ownership relation of debugging information entries is achieved naturally because the
     debugging information is represented as a tree. The nodes of the tree are the debugging
     information entries themselves. The child entries of any node are exactly those debugging
     information entries owned by that node.
     A chain of sibling entries is terminated by a null entry.
    */
    enum DebuggingInfoEntry: String {
        case DW_TAG_access_declaration      = "DW_TAG_access_declaration"
        case DW_TAG_array_type              = "DW_TAG_array_type"
        case DW_TAG_base_type               = "DW_TAG_base_type"
        case DW_TAG_catch_block             = "DW_TAG_catch_block"
        case DW_TAG_class_type              = "DW_TAG_class_type"
        case DW_TAG_common_block            = "DW_TAG_common_block"
        case DW_TAG_common_inclusion        = "DW_TAG_common_inclusion"
        /*
         An object ﬁle may be derived from one or more compilation units. Each such compilation unit will be described by a
         debugging information entry with the tag DW_TAG_compile_unit. A compilation unit typically represents the text and
         data contributed to an executable by a single relocatable object ﬁle. It may be derived from several source ﬁles,
         including pre-processed ‘‘include ﬁles.’’
         */
        case DW_TAG_compile_unit            = "DW_TAG_compile_unit"
        case DW_TAG_const_type              = "DW_TAG_const_type"
        case DW_TAG_constant                = "DW_TAG_constant"
        /// A Fortran entry point.
        case DW_TAG_entry_point             = "DW_TAG_entry_point"
        case DW_TAG_enumeration_type        = "DW_TAG_enumeration_type"
        case DW_TAG_enumerator              = "DW_TAG_enumerator"
        case DW_TAG_file_type               = "DW_TAG_file_type"
        case DW_TAG_formal_parameter        = "DW_TAG_formal_parameter"
        case DW_TAG_friend                  = "DW_TAG_friend"
        case DW_TAG_imported_declaration    = "DW_TAG_imported_declaration"
        case DW_TAG_inheritance             = "DW_TAG_inheritance"
        /// A particular inlined instance of a subroutine or function.
        case DW_TAG_inlined_subroutine      = "DW_TAG_inlined_subroutine"
        case DW_TAG_label                   = "DW_TAG_label"
        case DW_TAG_lexical_block           = "DW_TAG_lexical_block"
        case DW_TAG_member                  = "DW_TAG_member"
        case DW_TAG_module                  = "DW_TAG_module"
        case DW_TAG_namelist                = "DW_TAG_namelist"
        case DW_TAG_namelist_item           = "DW_TAG_namelist_item"
        case DW_TAG_packed_type             = "DW_TAG_packed_type"
        case DW_TAG_pointer_type            = "DW_TAG_pointer_type"
        case DW_TAG_ptr_to_member_type      = "DW_TAG_ptr_to_member_type"
        case DW_TAG_reference_type          = "DW_TAG_reference_type"
        case DW_TAG_set_type                = "DW_TAG_set_type"
        case DW_TAG_string_type             = "DW_TAG_string_type"
        case DW_TAG_structure_type          = "DW_TAG_structure_type"
        /// A global or ﬁle static subroutine or function.
        case DW_TAG_subprogram              = "DW_TAG_subprogram"
        case DW_TAG_subrange_type           = "DW_TAG_subrange_type"
        case DW_TAG_subroutine_type         = "DW_TAG_subroutine_type"
        case DW_TAG_template_type_param     = "DW_TAG_template_type_param"
        case DW_TAG_template_value_param    = "DW_TAG_template_value_param"
        case DW_TAG_thrown_type             = "DW_TAG_thrown_type"
        case DW_TAG_try_block               = "DW_TAG_try_block"
        case DW_TAG_typedef                 = "DW_TAG_typedef"
        case DW_TAG_union_type              = "DW_TAG_union_type"
        case DW_TAG_unspecified_parameters  = "DW_TAG_unspecified_parameters"
        case DW_TAG_variable                = "DW_TAG_variable"
        case DW_TAG_variant                 = "DW_TAG_variant"
        case DW_TAG_variant_part            = "DW_TAG_variant_part"
        case DW_TAG_volatile_type           = "DW_TAG_volatile_type"
        case DW_TAG_with_stmt               = "DW_TAG_with_stmt"
    }
    
    /**
     Each attribute value is characterized by an attribute name.
     The permissible values for an attribute belong to one or more classes of attribute value forms.
     Attribute value forms may belong to one of the following classes:
        address: Refers to some location in the address space of the described program.
        block:      An arbitrary number of uninterpreted bytes of data.
        constant:   One, two, four or eight bytes of uninterpreted data, or data encoded in the
                variable length format known as LEB128
        flag:       A small constant that indicates the presence or absence of an attribute.
        reference:  Refers to some member of the set of debugging information entries that describe
                the program. There are two types of reference. The first is an offset relative to
                the beginning of the compilation unit in which the reference occurs and must refer
                to an entry within that same compilation unit. The second type of reference is the
                address of any debugging information entry within the same executable or shared
                object; it may refer to an entry in a different compilation unit from the uint
                containning the reference.
        string:     A null-terminated sequence of zero or more (non-null) bytes. Data in this form
                are generally printable strings. Strings may be represented directlt in the
                debugging information entry or as an offset in a separate string table.
     */
    enum AttributeTypes: String {
        case DW_AT_abstract_origin        = "DW_AT_abstract_origin"
        case DW_AT_accessibility          = "DW_AT_accessibility"
        /*
         Any debugging information entry representing a pointer or reference type or a subroutine or subroutine type may have
         a DW_AT_address_class attribute, whose value is a constant. The set of permissible values is speciﬁc to each target
         architecture.
         */
        case DW_AT_address_class          = "DW_AT_address_class"
        /*
         A compiler may wish to generate debugging information entries for objects or types that were not actually declared in
         the source of the application. An example is a formal parameter entry to represent the hidden this parameter that most
         C++ implementations pass as the ﬁrst argument to non-static member functions.
         
         Any debugging information entry representing the declaration of an object or type artiﬁcially generated by a compiler
         and not explicitly declared by the source program may have a DW_AT_artificial attribute. The value of this attribute is
         a ﬂag.
         */
        case DW_AT_artificial             = "DW_AT_artificial"
        /*
         A DW_AT_base_types attribute whose value is a reference. This attribute points to a debugging information entry
         representing another compilation unit. It may be used to specify the compilation unit containing the base type entries
         used by entries in the current compilation unit.
         */
        case DW_AT_base_types             = "DW_AT_base_types"
        case DW_AT_bit_offset             = "DW_AT_bit_offset"
        case DW_AT_byte_size              = "DW_AT_byte_size"
        case DW_AT_common_reference       = "DW_AT_common_reference"
        /*
         A DW_AT_comp_dir attribute whose value is a null-terminated string containing the current working directory of the
         compilation command that produced this compilation unit in whatever form makes sense for the host system.
         */
        case DW_AT_comp_dir               = "DW_AT_comp_dir"
        case DW_AT_const_value            = "DW_AT_const_value"
        case DW_AT_count                  = "DW_AT_count"
        /*
         The value of the DW_AT_decl_file attribute corresponds to a ﬁle number from the statement information table for the
         compilation unit containing this debugging information entry and represents the source ﬁle in which the declaration
         appeared
        */
        case DW_AT_decl_file              = "DW_AT_decl_file"
        case DW_AT_decl_column            = "DW_AT_decl_column"
        case DW_AT_decl_line              = "DW_AT_decl_line"
        /*
         Debugging information entries that represent non-deﬁning declarations of a program object or type have
         a DW_AT_declaration attribute, whose value is a ﬂag.
        */
        case DW_AT_declaration            = "DW_AT_declaration"
        case DW_AT_default_value          = "DW_AT_default_value"
        case DW_AT_discr_list             = "DW_AT_discr_list"
        case DW_AT_encoding               = "DW_AT_encoding"
        /*
         If the name of the subroutine described by an entry with the tag DW_TAG_subprogram is visible outside of its containing
         compilation unit, that entry has a DW_AT_external attribute, whose value is a ﬂag.
         */
        case DW_AT_external               = "DW_AT_external"
        case DW_AT_frame_base             = "DW_AT_frame_base"
        case DW_AT_high_pc                = "DW_AT_high_pc"
        case DW_AT_import                 = "DW_AT_import"
        case DW_AT_is_optional            = "DW_AT_is_optional"
        case DW_AT_language               = "DW_AT_language"
        case DW_AT_location               = "DW_AT_location"
        case DW_AT_lower_bound            = "DW_AT_lower_bound"
        /*
         A DW_AT_macro_info attribute whose value is a reference to the macro information for this compilation unit.
         This information is placed in a separate object ﬁle section from the debugging information entries themselves. The value
         of the macro information attribute is the offset in the .debug_macinfo section of the ﬁrst byte of the macro information
         for this compilation unit.
         */
        case DW_AT_macro_info             = "DW_AT_macro_info"
        /*
         Any debugging information entry representing a program entity that has been given a name may have a DW_AT_name attribute,
         whose value is a string representing the name as it appears in the source program.
        */
        case DW_AT_name                   = "DW_AT_name"
        case DW_AT_ordering               = "DW_AT_ordering"
        case DW_AT_producer               = "DW_AT_producer"
        case DW_AT_return_addr            = "DW_AT_return_addr"
        case DW_AT_sibling                = "DW_AT_sibling"
        case DW_AT_start_scope            = "DW_AT_start_scope"
        /*
         Any debugging information entry that contains a description of the location of an object or subroutine may have a
         DW_AT_segment attribute, whose value is a location description. If the entry containing the DW_AT_segment attribute has
         a DW_AT_low_pc or DW_AT_high_pc attribute, or a location description that evaluates to an address, then those values
         represent the offset portion of the address within the segment speciﬁed by
         */
        case DW_AT_segment                = "DW_AT_segment"
        /*
         A DW_AT_stmt_list attribute whose value is a reference to line number information for this compilation unit.
         This information is placed in a separate object ﬁle section from the debugging information entries themselves. The value
         of the statement list attribute is the offset in the .debug_line section of the ﬁrst byte of the line number information
         for this compilation unit.
         */
        case DW_AT_stmt_list              = "DW_AT_stmt_list"
        case DW_AT_string_length          = "DW_AT_string_length"
        /*
         If the subroutine or entry point is a function that returns a value, then its debugging information entry has a
         DW_AT_type attribute to denote the type returned by that function.
         Debugging information entries for C void functions should not have an attribute for the return type.
         In ANSI-C there is a difference between the types of functions declared using function prototype style declarations
         and those declared using non-prototype declarations.
         A subroutine entry declared with a function prototype style declaration may have a DW_AT_prototyped attribute, whose
         value is a ﬂag.
         */
        case DW_AT_type                   = "DW_AT_type"
        case DW_AT_upper_bound            = "DW_AT_upper_bound"
        case DW_AT_variable_parameter     = "DW_AT_variable_parameter"
        case DW_AT_visibility             = "DW_AT_visibility"
    }
    
    /// Register Name Operators, used to name a register
    enum RegisterNameOperators: String {
        case DW_OP_reg0     = "DW_OP_reg0"
        case DW_OP_reg1     = "DW_OP_reg1"
        case DW_OP_reg2     = "DW_OP_reg2"
        case DW_OP_reg3     = "DW_OP_reg3"
        case DW_OP_reg4     = "DW_OP_reg4"
        case DW_OP_reg5     = "DW_OP_reg5"
        case DW_OP_reg6     = "DW_OP_reg6"
        case DW_OP_reg7     = "DW_OP_reg7"
        case DW_OP_reg8     = "DW_OP_reg8"
        case DW_OP_reg9     = "DW_OP_reg9"
        case DW_OP_reg10    = "DW_OP_reg10"
        case DW_OP_reg11    = "DW_OP_reg11"
        case DW_OP_reg12    = "DW_OP_reg12"
        case DW_OP_reg13    = "DW_OP_reg13"
        case DW_OP_reg14    = "DW_OP_reg14"
        case DW_OP_reg15    = "DW_OP_reg15"
        case DW_OP_reg16    = "DW_OP_reg16"
        case DW_OP_reg17    = "DW_OP_reg17"
        case DW_OP_reg18    = "DW_OP_reg18"
        case DW_OP_reg19    = "DW_OP_reg19"
        case DW_OP_reg20    = "DW_OP_reg20"
        case DW_OP_reg21    = "DW_OP_reg21"
        case DW_OP_reg22    = "DW_OP_reg22"
        case DW_OP_reg23    = "DW_OP_reg23"
        case DW_OP_reg24    = "DW_OP_reg24"
        case DW_OP_reg25    = "DW_OP_reg25"
        case DW_OP_reg26    = "DW_OP_reg26"
        case DW_OP_reg27    = "DW_OP_reg27"
        case DW_OP_reg28    = "DW_OP_reg28"
        case DW_OP_reg29    = "DW_OP_reg29"
        case DW_OP_reg30    = "DW_OP_reg30"
        case DW_OP_reg31    = "DW_OP_reg31"
        /// this has a single unsigned LEB128 literal operand that encodes the name of a register
        case DW_OP_regx     = "DW_OP_regx"
    }
    
    /// The addressing expression represented by a location expression, if evaluated, generates the runtime address of the value
    /// of a symbol except where the DW_OP_regn, or DW_OP_regx operations are used.
    enum AddressingOperations {
        /// Push a value onto the addressing stack
        enum LiteralEncoding: String {
            // DW_OP_litn operations encode the unsigned literal values from 0 through 31, inclusive
            case DW_OP_lit0     = "DW_OP_lit0"
            case DW_OP_lit1     = "DW_OP_lit1"
            case DW_OP_lit2     = "DW_OP_lit2"
            case DW_OP_lit3     = "DW_OP_lit3"
            case DW_OP_lit4     = "DW_OP_lit4"
            case DW_OP_lit5     = "DW_OP_lit5"
            case DW_OP_lit6     = "DW_OP_lit6"
            case DW_OP_lit7     = "DW_OP_lit7"
            case DW_OP_lit8     = "DW_OP_lit8"
            case DW_OP_lit9     = "DW_OP_lit9"
            case DW_OP_lit10    = "DW_OP_lit10"
            case DW_OP_lit11    = "DW_OP_lit11"
            case DW_OP_lit12    = "DW_OP_lit12"
            case DW_OP_lit13    = "DW_OP_lit13"
            case DW_OP_lit14    = "DW_OP_lit14"
            case DW_OP_lit15    = "DW_OP_lit15"
            case DW_OP_lit16    = "DW_OP_lit16"
            case DW_OP_lit17    = "DW_OP_lit17"
            case DW_OP_lit18    = "DW_OP_lit18"
            case DW_OP_lit19    = "DW_OP_lit19"
            case DW_OP_lit20    = "DW_OP_lit20"
            case DW_OP_lit21    = "DW_OP_lit21"
            case DW_OP_lit22    = "DW_OP_lit22"
            case DW_OP_lit23    = "DW_OP_lit23"
            case DW_OP_lit24    = "DW_OP_lit24"
            case DW_OP_lit25    = "DW_OP_lit25"
            case DW_OP_lit26    = "DW_OP_lit26"
            case DW_OP_lit27    = "DW_OP_lit27"
            case DW_OP_lit28    = "DW_OP_lit28"
            case DW_OP_lit29    = "DW_OP_lit29"
            case DW_OP_lit30    = "DW_OP_lit30"
            case DW_OP_lit31    = "DW_OP_lit31"
            /// The DW_OP_addr operation has a single operand that encodes a machine address and whose size is the
            /// size of an address on the target machine.
            case DW_OP_addr     = "DW_OP_addr"
            case DW_OP_const1u  = "DW_OP_const1u"
            case DW_OP_const1s  = "DW_OP_const1s"
            case DW_OP_const2u  = "DW_OP_const2u"
            case DW_OP_const2s  = "DW_OP_const2s"
            case DW_OP_const4u  = "DW_OP_const4u"
            case DW_OP_const4s  = "DW_OP_const4s"
            case DW_OP_const8u  = "DW_OP_const8u"
            case DW_OP_const8s  = "DW_OP_const8s"
            /// DW_OP_constu provides an unsigned LEB 128 integer constant
            case DW_OP_constu   = "DW_OP_constu"
            /// DW_OP_constu provides an signed LEB 128 integer constant
            case DW_OP_consts   = "DW_OP_consts"
        }
        
        /// Push a value onto the stack that is the result of adding the contents of a register with a given signed offset.
        enum RegisterBasedAddressing: String {
            /// provides a signed LEB128 offset from the address speciﬁed by the location descriptor in the DW_AT_frame_base
            /// attribute of the current function. (This is typically a "stack pointer" register plus or minus some offset.
            /// On more sophisticated systems it might be a location list that adjusts the offset according to changes in the
            /// stack pointer as the PC changes.)
            case DW_OP_fbreg    = "DW_OP_fbreg"
            case DW_OP_breg0    = "DW_OP_breg0"
            case DW_OP_breg1    = "DW_OP_breg1"
            case DW_OP_breg2    = "DW_OP_breg2"
            case DW_OP_breg3    = "DW_OP_breg3"
            case DW_OP_breg4    = "DW_OP_breg4"
            case DW_OP_breg5    = "DW_OP_breg5"
            case DW_OP_breg6    = "DW_OP_breg6"
            case DW_OP_breg7    = "DW_OP_breg7"
            case DW_OP_breg8    = "DW_OP_breg8"
            case DW_OP_breg9    = "DW_OP_breg9"
            case DW_OP_breg10   = "DW_OP_breg10"
            case DW_OP_breg11   = "DW_OP_breg11"
            case DW_OP_breg12   = "DW_OP_breg12"
            case DW_OP_breg13   = "DW_OP_breg13"
            case DW_OP_breg14   = "DW_OP_breg14"
            case DW_OP_breg15   = "DW_OP_breg15"
            case DW_OP_breg16   = "DW_OP_breg16"
            case DW_OP_breg17   = "DW_OP_breg17"
            case DW_OP_breg18   = "DW_OP_breg18"
            case DW_OP_breg19   = "DW_OP_breg19"
            case DW_OP_breg20   = "DW_OP_breg20"
            case DW_OP_breg21   = "DW_OP_breg21"
            case DW_OP_breg22   = "DW_OP_breg22"
            case DW_OP_breg23   = "DW_OP_breg23"
            case DW_OP_breg24   = "DW_OP_breg24"
            case DW_OP_breg25   = "DW_OP_breg25"
            case DW_OP_breg26   = "DW_OP_breg26"
            case DW_OP_breg27   = "DW_OP_breg27"
            case DW_OP_breg28   = "DW_OP_breg28"
            case DW_OP_breg29   = "DW_OP_breg29"
            case DW_OP_breg30   = "DW_OP_breg30"
            case DW_OP_breg31   = "DW_OP_breg31"
            /// DW_OP_bregx operation has two operands: a signed LEB128 offset from the specified register which is defined
            /// with an unsigned LEB128 number.
            case DW_OP_bregx    = "DW_OP_bregx"
        }
        /// Stack Operations manipulate the "location stack". Location operations that index the location stack assume that the
        /// top of the stack(most recently added entry) has index 0.
        enum StackOperation: String {
            /// duplicates the value at the top of the location stack.
            case DW_OP_dup      = "DW_OP_dup"
            /// pops the value at the top of the stack.
            case DW_OP_drop     = "DW_OP_drop"
            /// provides a 1-byte index. The stack entry with the specified index (0 through 255, inclusive) is pushed on the stack.
            case DW_OP_pick     = "DW_OP_pick"
            /// depublicates the entry currently second in the stack at the top of the stack.
            /// This is equivalent to an DW_OP_pick operation, with index 1.
            case DW_OP_over     = "DW_OP_over"
            /// swaps the top two stack entries.
            case DW_OP_swap     = "DW_OP_swap"
            /// rotates the first three stack entries.
            case DW_OP_rot      = "DW_OP_rot"
            /// pops the top stack entry and treats it as an address. The value retrieved from that address is pushed. The size of
            /// the data retrieved from dereferenced address is the size of an address on the target machine.
            case DW_OP_deref    = "DW_OP_deref"
            /// This is similar to DW_OP_deref, but the size of the value is specified by the single operand.
            case DW_OP_deref_size   = "DW_OP_deref_size"
            /// provides an exrended dereference mechanism. The entry at the top of the stack is treated as an address.
            /// The second stack entry is treated as an "address space identifier" for those architectures that support
            /// multiple address spaces. The top two stack elements are poped, a data item is retrieved through an
            /// implementation-defined address calculation and pushed as the new stack top. The size of the data retrieved
            /// from the dereferenced address is the size of an address on the target machine.
            case DW_OP_xderef   = "DW_OP_xderef"
            /// This is similar to DW_OP_deref, but the size of the value is specified by the single operand.
            case DW_OP_xderef_size  = "DW_OP_xderef_size"
        }
        
        enum ArithmeticAndLogicalOperation: String {
            /// pops the top stack entry and pushes its absolute value.
            case DW_OP_abs      = "DW_OP_abs"
            /// pops the top two stack values, performs a bitwise and operation on the two, and pushes the result.
            case DW_OP_and      = "DW_OP_and"
            /// pops the top two stack values, divides the former second entry by the former top of the stack using
            /// signed division, and pushes the result.
            case DW_OP_div      = "DW_OP_div"
            /// pops the top two stack values, subtracts the former top of the stack from the former second entry, and
            /// pushes the result.
            case DW_OP_minus    = "DW_OP_minus"
            /// pops the top two stack values and pushes the result of the calculation: former second stack entry modulo the
            /// former top of the stack.
            case DW_OP_mod      = "DW_OP_mod"
            /// pops the top two stack entries, multiplies them together, and pushes the result.
            case DW_OP_mul      = "DW_OP_mul"
            /// pops the top stack entry, and pushes its negation.
            case DW_OP_neg      = "DW_OP_neg"
            /// pops the top stack entry, and pushes its bitwise complement.
            case DW_OP_not      = "DW_OP_not"
            /// pops the top two stack entries, performs a bitwise or operation on the two, and pushes the result.
            case DW_OP_or       = "DW_OP_or"
            /// pops the top two stack entries, adds them together, and pushes the result.
            case DW_OP_plus     = "DW_OP_plus"
            /// pops the top stack entry, adds it to the unsigned LEB128 constant operand and pushes the result. This operation
            /// is supplied specifically to be able to encode more field offsets in two bytes than can be done with "DW_OP_litn
            /// DW_OP_add"
            case DW_OP_plus_uconst  = "DW_OP_plus_uconst"
            /// pops the top two stack entries, shift the former second entry left by the number of bits specified by the former
            /// top of the stack, and pushes the result.
            case DW_OP_shl      = "DW_OP_shl"
            /// pops the top two stack entries, shift the former second entry right (logically) by the number of bits specified
            /// by the former top of the stack, and pushes the result
            case DW_OP_shr      = "DW_OP_shr"
            /// pops the top two stack entries, shift the former second entry right (arithmetically) by the number of bits
            /// specified by the former top of the stack, and pushes the result.
            case DW_OP_shra     = "DW_OP_shra"
            /// pops the top two stack entries, performs the logical exclusive-or operation on the two, and pushes the result.
            case DW_OP_xor      = "DW_OP_xor"
        }
        /// Control Flow Operation provides simple control of the ﬂow of a location expression.
        enum ControlFlowOperation: String {
            // The six relational operators each pops the top two stack values, compares the former top of the stack with the
            // former second entry, and pushes the constant value 1 onto the stack if the result of the operation is true or
            // the constant value 0 if the result of the operation is false.
            case DW_OP_le       = "DW_OP_le"
            case DW_OP_ge       = "DW_OP_ge"
            case DW_OP_eq       = "DW_OP_eq"
            case DW_OP_lt       = "DW_OP_lt"
            case DW_OP_gt       = "DW_OP_gt"
            case DW_OP_ne       = "DW_OP_ne"
            /// an unconditional branch. Its single operand is a 2-byte signed integer constant. The 2-byte constant is the number
            /// of bytes of the location expression to skip from the current operation, beginning after the 2-byte constant.
            case DW_OP_skip     = "DW_OP_skip"
            /// DW_OP_bra is a conditional branch. Its single operand is a 2-byte signed integer constant. This operation pops the
            /// top of stack. If the value popped is not the constant 0, the 2-byte constant operand is the number of bytes of the
            /// location expression to skip from the current operation, beginning after the 2-byte constant.
            case DW_OP_bra      = "DW_OP_bra"
        }
        
        enum SpecialOperation: String {
            /// Many compilers store a single variable in sets of registers, or store a variable partially in memory and partially
            /// in registers. DW_OP_piece provides a way of describing how large a part of a variable a particular addressing
            /// expression refers to.
            /// DW_OP_piece takes a single argument which is an unsigned LEB128 number. The number describes the size in bytes of
            /// the piece of the object referenced by the addressing expression whose result is at the top of the stack.
            case DW_OP_piece    = "DW_OP_piece"
            /// The DW_OP_nop operation is a place holder. It has no effect on the location stack or any of its values.
            case DW_OP_nop      = "DW_OP_nop"
        }
    }
    
    enum AccessibilityOfDeclarations: String {
        case DW_ACCESS_public       = "DW_ACCESS_public"
        case DW_ACCESS_private      = "DW_ACCESS_private"
        case DW_ACCESS_protected    = "DW_ACCESS_protected"
    }
    
    enum VisibilityOfDeclarations: String {
        case DW_VIS_local           = "DW_VIS_local"
        case DW_VIS_exported        = "DW_VIS_exported"
        case DW_VIS_qualified       = "DW_VIS_qualified"
    }
    
    enum VirtualityOfDeclaration: String {
        case DW_VIRTUALITY_none         = "DW_VIRTUALITY_none"
        case DW_VIRTUALITY_virtual      = "DW_VIRTUALITY_virtual"
        case DW_VIRTUALITY_pure_virtual = "DW_VIRTUALITY_pure_virtual"
    }
    
    enum AddressClass: Int {
        case DW_ADDR_none   = 0
        case DW_ADDR_near16 = 1
        case DW_ADDR_far16  = 2
        case DW_ADDR_huge16 = 3
        case DW_ADDR_near32 = 4
        case DW_ADDR_far32  = 5
    }
    
    enum Language: String {
        case DW_LANG_C              = "DW_LANG_C"
        case DW_LANG_C89            = "DW_LANG_C89"
        case DW_LANG_C_plus_plus    = "DW_LANG_C_plus_plus"
        case DW_LANG_Fortran77      = "DW_LANG_Fortran77"
        case DW_LANG_Fortran90      = "DW_LANG_Fortran90"
        case DW_LANG_Modula2        = "DW_LANG_Modula2"
        case DW_LANG_Pascal83       = "DW_LANG_Pascal83"
    }
}


