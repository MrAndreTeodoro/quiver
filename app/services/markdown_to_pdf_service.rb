class MarkdownToPdfService
  def initialize(markdown, output_path)
    @markdown    = markdown
    @output_path = output_path
  end

  def call
    Prawn::Document.generate(@output_path, page_size: "A4", margin: [ 42, 42, 42, 42 ]) do |pdf|
      pdf.font "Helvetica"
      parse_lines(pdf)
    end
  end

  private

  def parse_lines(pdf)
    @markdown.each_line do |line|
      line = line.chomp
      if    line.start_with?("# ")
        pdf.move_down 10
        pdf.text line.sub("# ", ""), size: 16, style: :bold
        pdf.move_down 6
      elsif line.start_with?("## ")
        pdf.move_down 8
        pdf.text line.sub("## ", ""), size: 13, style: :bold
        pdf.move_down 4
      elsif line.start_with?("### ")
        pdf.move_down 4
        pdf.text line.sub("### ", ""), size: 11, style: :bold
      elsif line.match?(/^[-*] /)
        pdf.text "  \u2022 #{line.sub(/^[-*] /, "")}", size: 10
      elsif line.strip.empty?
        pdf.move_down 6
      else
        pdf.text line, size: 10
      end
    end
  end
end
