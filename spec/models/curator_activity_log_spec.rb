require File.dirname(__FILE__) + '/../spec_helper'

describe CuratorActivityLog do

  # TODO.  Sorry, there's just way too much to do here to bother right now.  It was completely wrong, before.

  # TODO - make sure all of these methods are actually USED.  I'm not so sure.

  it 'should know the #taxon_concept_name for a data object'
  it 'should know the #taxon_concept_name for a comment'
  it 'should know the #taxon_concept_name for user submitted text'
  it 'should know the #taxon_concept_name for a synonym'
  it 'should raise an exception for #taxon_concept_name for other types of objects'

  it 'should find images from a taxon concept'
  it 'should find dohes from a TC'
  it 'should find cdohes from a TC'
  it 'should find taxon_concept_names from a TC'
  it 'should find synonyms from a TC'

  it 'should know the id for a data object'
  it 'should know the id for a comment'
  it 'should know the id for user submitted text'
  it 'should know the id for a synonym'
  it 'should raise an exception for #taxon_concept_name for other types of objects'

  it 'should return the label of a data type for #data_object_type'

  it 'should use the label from the first toc_item fir #toc_label'

  it 'should find the comment object'

  it 'should grab a #comment_parent'

  it 'should find the #synonym'

  it 'should find the #users_data_object'

  it 'should find the #udo_parent_text'

  it 'should find the #udo_taxon_concept'

end
