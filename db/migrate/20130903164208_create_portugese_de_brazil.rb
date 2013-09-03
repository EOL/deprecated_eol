# encoding: utf-8
class CreatePortugeseDeBrazil < ActiveRecord::Migration
  def up
    unless Language.exists?(iso_639_1: 'pt-BR')
      Language.create(iso_639_1: "pt-BR", iso_639_2: "", iso_639_3: "", source_form: "português do Brasil", sort_order: 1,
                      activated_on: Time.now)
    end
  end

  def down
    # Nothing to do.
  end
end
