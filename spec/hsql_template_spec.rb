require 'pry'
require_relative '../lib/hsql/template'

RSpec.describe HSQL::Template do
  let(:input) do
    <<-MUSTACHE
SELECT * FROM {{{table1}}} WHERE {{{where}}} AND unsafe = "{{escaped_where}}";
{{#array_of_data}}
INSERT INTO summary_{{date}} SELECT * from summaries
{{#condition}}
  WHERE date = {{date}}
{{/condition}}
{{/array_of_data}}
;
MUSTACHE
  end
  let(:template) { HSQL::Template.new(input) }

  describe '#variable_names' do
    subject(:variable_names) { template.variable_names }

    it 'finds all variables, even conditionals and loops' do
      expect(variable_names).to eq(
        %w(table1 where escaped_where array_of_data date condition)
      )
    end
  end

  describe '#render' do
    let(:data) {{
      table1: 'the_table',
      where: 'name = "The Pope"',
      escaped_where: '"<unsafe; DROP TABLE bobby;>"',
      array_of_data: [
        {
          condition: true,
          date: '20220205',
        },
        {
          condition: true,
          date: '20220206',
        },
      ],
    }}
    subject(:render) { template.render(data) }

    it 'interpolates everything properly' do
      expect(render).to eql(<<-SQL)
SELECT * FROM the_table WHERE name = "The Pope" AND unsafe = "&quot;&lt;unsafe; DROP TABLE bobby;&gt;&quot;";
INSERT INTO summary_20220205 SELECT * from summaries
  WHERE date = 20220205
INSERT INTO summary_20220206 SELECT * from summaries
  WHERE date = 20220206
;
SQL
    end
  end
end