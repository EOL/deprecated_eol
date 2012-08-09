# EOL: the change here is to modify the select option if it is a hash of various selects
module ActiveRecord
  module QueryMethods
    def build_select(arel, selects)

      new_selects = selects.dup
      if selects && selects.first.class == Hash
        if selects.first[table.name.to_sym]
          new_selects = selects.first[table.name.to_sym]
        else
          new_selects = "*"
        end
      end
      
      unless new_selects.empty?
        @implicit_readonly = false
        arel.project(*new_selects)
      else
        arel.project(@klass.arel_table[Arel.star])
      end
    end
  end
end
