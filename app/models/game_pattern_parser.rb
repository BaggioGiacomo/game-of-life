class GamePatternParser
  class ParseError < StandardError; end

  MAX_DIMENSION = 100
  MAX_FILE_SIZE = 1.megabyte

  # Main entry point - detects format and parses accordingly
  def self.parse(file)
    # Handle different types of file parameters
    unless file.respond_to?(:read)
      raise ParseError, "Please select a file to upload."
    end

    validate_file_size!(file)

    content = file.read.force_encoding("UTF-8")
    extension = File.extname(file.original_filename).downcase

    # Try to detect format by extension first, then by content
    if extension == ".rle"
      parse_rle(content)
    elsif extension.in?([ ".cells", ".txt" ])
      parse_plain_text(content)
    else
      raise ParseError, "Could not parse file. Please upload an RLE or plain text pattern."
    end
  end

  private

  def self.validate_file_size!(file)
    if file.size > MAX_FILE_SIZE
      raise ParseError, "File is too large. Maximum size is 1MB."
    end
  end

  def self.parse_rle(content)
    lines = content.lines.map(&:strip)

    # Find header line with dimensions
    header_line = lines.find { |line| line.match?(/x\s*=\s*\d+.*y\s*=\s*\d+/i) }
    raise ParseError, "Invalid RLE format: missing header with dimensions" unless header_line

    # Extract dimensions
    width_match = header_line.match(/x\s*=\s*(\d+)/i)
    height_match = header_line.match(/y\s*=\s*(\d+)/i)

    raise ParseError, "Invalid RLE format: could not parse dimensions" unless width_match && height_match

    width = width_match[1].to_i
    height = height_match[1].to_i

    validate_dimensions!(width, height)

    # Find pattern data (skip comments and header)
    pattern_lines = lines.reject { |line| line.empty? || line.start_with?("#") || line.match?(/x\s*=.*y\s*=/i) }
    pattern_data = pattern_lines.join

    # Remove end marker if present
    pattern_data = pattern_data.sub(/!$/, "")

    # Parse RLE pattern
    grid = Array.new(height) { Array.new(width, false) }
    row = 0
    col = 0

    pattern_data.scan(/(\d*)([bo$])/) do |count, char|
      count = count.empty? ? 1 : count.to_i

      case char
      when "b" # dead cells
        col += count
      when "o" # alive cells
        count.times do
          break if col >= width
          grid[row][col] = true if row < height
          col += 1
        end
      when "$" # end of line
        row += count
        col = 0
      end
    end

    living_cells = extract_living_cells(grid)
    raise ParseError, "No living cells found in the pattern." if living_cells.empty?

    { width: width, height: height, living_cells: living_cells }
  end

  def self.parse_plain_text(content)
    lines = content.lines.map(&:strip).reject(&:empty?)

    raise ParseError, "Empty pattern file" if lines.empty?

    height = lines.size
    width = lines.map(&:length).max

    validate_dimensions!(width, height)

    grid = Array.new(height) { Array.new(width, false) }

    lines.each_with_index do |line, row|
      line.chars.each_with_index do |char, col|
        # Support various alive cell representations
        grid[row][col] = true if char.in?([ "O", "*", "X", "1" ])
      end
    end

    living_cells = extract_living_cells(grid)
    raise ParseError, "No living cells found in the pattern." if living_cells.empty?

    { width: width, height: height, living_cells: living_cells }
  end

  def self.validate_dimensions!(width, height)
    if width > MAX_DIMENSION || height > MAX_DIMENSION
      raise ParseError, "Pattern is too large. Maximum size is #{MAX_DIMENSION}x#{MAX_DIMENSION}."
    end

    if width <= 0 || height <= 0
      raise ParseError, "Invalid pattern dimensions."
    end
  end

  def self.extract_living_cells(grid)
    cells = []
    grid.each_with_index do |row, row_idx|
      row.each_with_index do |cell, col_idx|
        cells << [ row_idx, col_idx ] if cell
      end
    end
    cells
  end
end
