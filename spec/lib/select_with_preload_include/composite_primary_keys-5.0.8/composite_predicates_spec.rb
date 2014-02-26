require "spec_helper"

describe CompositePrimaryKeys::Predicates do

  let(:wrapper) do
    class MyModuleWrapper
      include CompositePrimaryKeys::Predicates
    end
    MyModuleWrapper.new
  end

  describe '#cpk_or_predicate' do

    it 'uses IN when possible' do
      wrapper.stub(:figure_engine).and_return(nil) # TODO - try removing this, might just be nil.
      predicate1 = stub(Object, to_sql: "`table`.`field` = 23")
      predicate2 = stub(Object, to_sql: "`table`.`field` = 34")
      predicates = [predicate1, predicate2]
      Arel::Nodes::SqlLiteral.should_receive(:new).with("(`table`.`field` IN (23,34))")
      wrapper.cpk_or_predicate(predicates)
    end

    it 'uses OR' do
      wrapper.stub(:figure_engine).and_return(nil) # TODO - try removing this, might just be nil.
      predicate1 = stub(Object, to_sql: "first sql")
      predicate2 = stub(Object, to_sql: "second sql")
      predicates = [predicate1, predicate2]
      Arel::Nodes::SqlLiteral.should_receive(:new).with("((first sql) OR (second sql))")
      wrapper.cpk_or_predicate(predicates)
    end

  end

end
