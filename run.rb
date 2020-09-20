source_filepath = ARGV[0]

chunk = []
section = 'NONE'
table_name = ''
start_recording = false

# Necessary for very big files.
def write_file(filepath, content)
  File.open(filepath, 'wb') do |f|
    StringIO.open(content) do |io|
      until io.eof?
        f.write(io.read(1024 * 60))
      end
    end
  end
end

def create_table_filepath(table_name)
  "./out/create_tables/#{table_name}.sql"
end

def insert_rows_filepath(table_name)
  "./out/insert_rows/#{table_name}.sql"
end

File.open(source_filepath, 'r').each do |line|

  if line.size < 200
    matches = line.match(/Table structure for table `([\w]+)`/)
    if matches && !matches[1].nil?

      # If we're about to start a new table, clear whatever was there before.
      if section == 'INSERT_ROWS' && !chunk.empty?
        output_filepath = insert_rows_filepath(table_name)
        puts "Dumped #{output_filepath}"
        write_file(output_filepath, chunk.join("\n"))
        chunk = []
      end

      puts "Line: #{line}"
      table_name = matches[1]
      section = 'CREATE_TABLE'
      puts "Start recording ... #{table_name}"
      start_recording = true
    end
  end

  # Don't match if this is one those super long lines that may have binary information
  if line.size < 200
    matches = line.match(/Dumping data for table `([\w]+)`/)
    if matches && !matches[1].nil?
      puts "Line: #{line}"
      if section == 'CREATE_TABLE'
        output_filepath = create_table_filepath(table_name)
        puts "Dumped #{output_filepath}"
        write_file(output_filepath, chunk.join("\n"))

        chunk = []
        table_name = matches[1]
        section = 'INSERT_ROWS'
        next
      end
    end
  end

  chunk << line if start_recording
end
