require 'es_aggs_json_editor/version'
require 'json'

module EsAggsJsonEditor
  attr_reader :aggs

  DefaultExtract = ->(bucket, enum, human_enum){
    enum << bucket['key']
    human_enum << bucket['doc_count']
  }

  def terms term, mapping_name: term, append_method: 'append', &block
    block ||= DefaultExtract
    enum, append = [], []

    aggs[term]['buckets'].each do |bucket|
      block[bucket, enum, append]
    end

    choices[mapping_name] = {'enum' => enum, 'append' => append}
  end

  def to_js
    "(function(){"\
      "#{js_basic_json}"\
      "#{js_options}"\
      "var container = document.getElementById('jsoneditor');"\
      "var editor = new JSONEditor(container, options, json);"\
      "editor.expandAll();"\
    "})()"
  end

  private

  def choices
    @choices ||= {}
  end

  def templates
    choices.keys.map do |k|
      {
        text: k,
        value: {
          terms: {
            k => []
          }
        }
      }
    end
  end

  def options
    {
      mode: 'tree',
      modes: ['code', 'text', 'tree'],
      schema: {},
      choices: choices,
      templates: templates
    }
  end

  def js_options
    "var options=#{options.to_json};"
  end

  def js_basic_json
    basic_json = {bool: {must: [], must_not: []}}
    "var json=#{basic_json.to_json};"
  end

end
