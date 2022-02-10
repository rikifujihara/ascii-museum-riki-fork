FILES_PATTERN = "**/*.txt"

def signatures
  files = Dir.glob(FILES_PATTERN)
  signatures = []
  files.each do |f|
    signatures << File.readlines(f).grep(/^\*/).flatten
  end
  signatures = signatures.flatten.map do |s|
    s.sub("* ", '').strip
  end
  signatures.group_by{|e| e}.map{|k, v| [k, v.length]}.to_h
end

def signatures_manifest
  File.readlines('signatures_manifest.csv').inject({}) do |manifest, l|
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

if signatures_manifest == signatures
  puts "Manifest is correct"
  exit 0
else
  puts "Manifest is incorrect"
  diff(signatures_manifest, signatures)
  exit 1
end