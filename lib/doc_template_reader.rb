require 'rubyXL'
class DocTemplateReader
  
  # class for read and write template file
  # - get all fields
  # - replace mapped fields to template .. [<NAME>]
  # - input file and output file format is only XLSX
  
  XLSX_FEXT = ".xlsx"

  def initialize(template_file)
    @template_filepath = template_file
    @errors = []
    @workbook = nil
    @fields = {}
    @all_fields = []
    initial_template
  end
  
  def mapped_fields
    # data structure format json
    # title: <name>
    # name: <name>
    # readonly: false
    @mapped_fields = []
    @all_fields.each do |f|
      @mapped_fields << {
        title: (f[:name].gsub(/_|-|\[|\]/," ")).strip.capitalize,
        name: f[:name],
        readonly: false
      }
    end
    return @mapped_fields
  end
  
  def fields
    # list of fields in template by sheet
    @fields
  end
  
  def all_fields
    # list of fields in template (unique field)
    @all_fields
  end
  
  def errors
    @errors
  end
  
  def write_to_file(output_file, params=nil)
    unless params.nil?
      update_workbook(params)
    end
    @workbook.write(output_file)
    return output_file
  end
  
  def filepath
    @template_filepath
  end
  
  private
  
  def initial_template
    begin
      parse_xlsx
      read_workbook
    rescue => e
      Rails.logger.error "DocTemplateReader error to read template file, #{e.message}"
      @errors << "Failed to read template file."
    end
  end

  def parse_xlsx
    if template_file?
      begin
        @workbook = RubyXL::Parser.parse(@template_filepath)
      rescue => e
        Rails.logger.error "DocTemplateReader error at RubyXL Parser, #{e.message}"
        @errors << "Failed to open template file (DocParser)."
      end
    else
      @errors << "Invalid template file."
    end
  end

  def read_workbook
    @workbook.worksheets.each do |worksheet|
      read_worksheet(worksheet)
    end
  end
  
  def read_worksheet(worksheet)
    fields = []
    worksheet.each do |row|
      row && row.cells.each do |cell|
        value = cell && cell.value
        if not value.nil? and not value.blank?
          field_names = find_fields_in_string(value)
          unless field_names.empty?
            fields.concat(field_names)
          end
        end
      end
    end
    @fields[worksheet.sheet_name] = fields.uniq
    @all_fields = @all_fields.concat(fields.uniq)
  end

  def update_workbook(params)
    @workbook.worksheets.each do |worksheet|
      worksheet.each do |row|
        row && row.cells.each do |cell|
          value = cell && cell.value
          if not value.nil? and not value.blank?
            field_names = find_fields_in_string(value)
            new_value = value
            unless field_names.empty?
              field_names.each do |f_name|
                xname = f_name[:name]
                if params[xname].present? or xname == "[SUMMARY_COMMENT]"
                  new_value = new_value.gsub(f_name[:name],params[xname])
                  # fix multiple rows
                  xflds, xvals = split_fields(f_name[:name],params[xname])
                  unless xflds.empty?
                    xflds.each_with_index do |fld,i|
                      #STDOUT.puts fld
                      #STDOUT.puts new_value
                      new_value = new_value.gsub(fld,xvals[i].to_s)
                    end
                  end
                else
                  # replace with empty
                  new_value = new_value.gsub(f_name[:name],"")
                end
              end
            end
            cell.change_contents(new_value)
          end
        end
      end
    end
  end
  
  def find_fields_in_string(value)
    fields = []
    result = value.to_s.scan(/(\[[A-Z0-9_:]+\])/)
    unless result.nil?
      result.flatten.each do |r|
        if corrent_field_name?(r)
          fields << field_prop(r)
        end
      end
    end
    return fields
  end
  
  def field_prop(name)
    name2 = name.gsub(/(:[0-9]+)/,"")
    return {
      name: name2
    }
  end
  
  def split_fields(field,value)
    # for field multiple rows
    fields = []
    values = []
    case field
    when "[SUMMARY_COMMENT]"
      values = split_comment_string(value)
      fields = 10.times.to_a.map { |i| "[SUMMARY_COMMENT:#{i+1}]" }
      values = 10.times.to_a.map { |i| values[i].to_s }
    end
    return fields, values
  end
  
  def corrent_field_name?(name)
    # must start with A-Z
    # contain only underscore, A-Z, 0-9
    return (name.gsub(/\[|\]/,"") =~ /^[A-Za-z][A-Za-z0-9_]*[A-Za-z0-9](:[0-9]+)?/)
  end
  
  def template_file?
    File.exists?(@template_filepath) and xlsx_file?
  end
  
  def xlsx_file?
    File.extname(@template_filepath) == XLSX_FEXT
  end
  
  def remove_bucket(s)
    s.gsub(/\[|\]/,"")
  end
  
  def split_comment_string(txt)
    txts = [""]
    txt.gsub(/( +)|(\r\n)/," ||").split("||").each do |t|
      next if t.length <= 0
      if txts[txts.length - 1].mb_chars.length + t.mb_chars.length < 100
        txts[txts.length - 1] << t
      else
        txts << t
      end
    end
    return txts
  end
  
end