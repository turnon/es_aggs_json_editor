require 'es_aggs_json_editor/version'
require 'json'

module EsAggsJsonEditor
  attr_reader :aggs

  DefaultExtract = ->(bucket, enum, human_enum){
    enum << bucket['key']
    human_enum << bucket['doc_count']
  }

  JsSchema = (
    {
      'type' => 'object',
      'properties' => {
        'must' => {
          'type' => 'array',
          'properties' => {
            'terms' => {
              'type' => 'object',
              'properties' => 'for_properties'
            }
          }
        },
        'must_not' => {
          'type' => 'array',
          'properties' => {
            'terms' => {
              'type' => 'object',
              'properties' => 'for_properties'
            }
          }
        }
      }
    }.to_json.gsub(/"for_properties"/, 'properties')
  )

  def terms term, mapping_name: term, human_enum_method: 'append_enum', &block
    block ||= DefaultExtract
    enum, human_enum = [], []

    aggs[term]['buckets'].each do |bucket|
      block[bucket, enum, human_enum]
    end

    items = {'enum' => enum}
    items[human_enum_method] = human_enum if human_enum_method

    properties[mapping_name] = {
      'type' => 'array',
      'items' => items
    }
  end

  def to_js
    "(function(){"\
      "#{js_basic_json}"\
      "#{js_properties}"\
      "#{js_options}"\
      "var container = document.getElementById('jsoneditor');"\
      "var editor = new JSONEditor(container, options, json);"\
      "editor.expandAll();"\
    "})()"
  end

  private

  def properties
    @properties ||= {}
  end

  def js_properties
    "var properties=#{properties.to_json};"
  end


  def templates
    properties.keys.map do |k|
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
      templates: templates
    }
  end

  def js_options
    "var options=#{options.to_json};options['schema']=#{JsSchema};"
  end

  def js_basic_json
    basic_json = {must: [], must_not: []}
    "var json=#{basic_json.to_json};"
  end

end
