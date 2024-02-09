require 'asciidoctor'
require 'yaml'

# Recursively resolve include directives
def resolve_includes(content, base_dir, included_files = [])
  content.gsub(/include::(.*?)\[(.*?)\]/) do |match|
    include_file = File.expand_path($1.strip, base_dir)
    include_options = $2.strip
    if File.exist?(include_file)
      included_files << include_file
      included_content = File.read(include_file)
      "// START PROCESSING: #{include_file}\n#{resolve_includes(included_content, File.dirname(include_file), included_files)}\n// END PROCESSING: #{include_file}"
    else
      raise "Include file not found: #{include_file}"
    end
  end
end

# Collect keyword attributes from the AST
def collect_keywords(content, current_filename)
  keywords_line = content.lines.find { |line| line.strip.start_with?(":keywords:") }
  return nil unless keywords_line

  keywords = keywords_line.gsub(":keywords:", "").strip.split(",").map(&:strip)

  return nil if keywords.empty?

  { 'file' => File.basename(current_filename, '.adoc'), 'path' => File.expand_path(current_filename), 'keywords' => keywords }
end

# Check if the filename argument is provided
if ARGV.empty?
  puts "Usage: ruby extract-asciidoc-keywords.rb <filename>"
  exit 1
end

filename = ARGV[0]

doc_content = File.read(filename)

# Collect keyword attributes from the parent file
parent_keywords = collect_keywords(doc_content, filename)

# Initialize an array to store collected keywords
all_keywords = [parent_keywords].compact

# Resolve include directives recursively
resolved_content = resolve_includes(doc_content, File.dirname(filename))

# Initialize an array to store collected keywords
current_filename = nil

# Collect keyword attributes from the resolved include files
resolved_content.each_line do |line|
  if line.start_with?("// START PROCESSING:")
    current_filename = line.gsub("// START PROCESSING:", "").strip
  elsif line.start_with?("// END PROCESSING:")
    current_filename = nil
  elsif current_filename
    keywords = collect_keywords(line, current_filename)
    all_keywords << keywords if keywords
  end
end

# Write the collected keywords to YAML out file
File.open('keywords.yaml', 'w') { |file| file.write(all_keywords.compact.to_yaml) }

# Create a new Asciidoctor Reader
reader = Asciidoctor::Reader.new(resolved_content)

# Parse the document
ast = reader.read

# Output the AST
puts ast
