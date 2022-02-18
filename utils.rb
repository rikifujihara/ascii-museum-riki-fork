FILES_PATTERN = "**/*.txt"
SIGNATURE_HEADER = "==header:signature"
BODY_START = "==body:start"
BODY_END = "==body:end"
SIGNATURE_MANIFEST_FILE = "signatures_manifest.csv"

def file_data
  files = Dir.glob(FILES_PATTERN)
  data = []
  files.each do |f|
    data << File.readlines(f).flatten
  end
  data.flatten
end

def signatures
  signatures = file_data.grep(/^\=\=header\:signature/)
  signatures = signatures.flatten.map do |s|
    s.sub("#{SIGNATURE_HEADER} ", '').strip
  end
  signatures.group_by{|e| e}.map{|k, v| [k, v.length]}.to_h
end

def signatures_manifest
  File.readlines(SIGNATURE_MANIFEST_FILE).inject({}) do |manifest, l|
    name, count = l.split(',')
    manifest[name.strip]= count.strip.to_i
    manifest
  end
end

def diff(signatures_manifest, signatures)
  signatures_manifest.keys.each do |k|
    if signatures.has_key?(k)
      if signatures[k] != signatures_manifest[k]
        puts "Expected #{k} to have #{signatures_manifest[k]} occurences, got #{signatures[k]}"
      end
    else
      puts "Missing #{k}, expected occurences: #{signatures_manifest[k]}"
    end
  end

  extra_signatures = signatures.keys - signatures_manifest.keys
  unless extra_signatures.size == 0
    puts "Found extra signatures: #{extra_signatures.join(', ')}"
  end 
end

def fetch_coords(data, start_tag, end_tag)
  data = file_data
  body_start_indices = data.each_index.select do |i| 
    data[i].strip == start_tag 
  end
  body_end_indices = data.each_index.select do |i| 
    data[i].strip == end_tag
  end
  body_start_indices.zip(body_end_indices)
end

def print_all_art
  data = file_data
  coords = fetch_coords(data, BODY_START, BODY_END)
  coords.each do |c|
    puts '*' * 10
    puts data[(c[0] + 1)..(c[1] - 1)].join('')
  end
end

if ARGV[0] == 'verify' 
  if signatures_manifest == signatures
    puts "Manifest is correct"
    exit 0
  else
    puts "Manifest is incorrect"
    diff(signatures_manifest, signatures)
    exit 1
  end
elsif ARGV[0] == 'print' 
  print_all_art
end
