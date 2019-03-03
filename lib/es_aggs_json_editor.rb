require 'es_aggs_json_editor/version'
require 'es_aggs_json_editor/assets'
require 'json'
require 'set'

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

    add_template({
      text: "terms:#{mapping_name}",
      value: {terms: {mapping_name => []}}
    })
  end

  def match_phrase field
    add_template({
      text: "match_phrase:#{field}",
      value: {match_phrase: {field => ''}}
    })
  end

  def match field
    add_template({
      text: "match:#{field}",
      value: {match: {field => ''}}
    })
  end

  def to_js
    "(function(){"\
      "#{js_basic_json}"\
      "#{js_options}"\
      "var container = document.getElementById('#{id}');"\
      "var editor = new JSONEditor(container, options, json);"\
      "editor.expandAll();"\
      "return editor;"\
    "})()"
  end

  private

  def id
    @id || 'jsoneditor'
  end

  def choices
    @choices ||= {}
  end

  def add_template tmpl
    (@templates ||= []) << tmpl
  end

  def templates
    tmpls = @templates.dup
    tmpls << {text: 'bool', value: basic_json}
  end

  def basic_json
    @basic_json || {bool: {must: [], must_not: []}}
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
    "var json=#{basic_json.to_json};"
  end

end
