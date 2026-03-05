class MarkdownToDocxService
  def initialize(markdown, output_path)
    @markdown    = markdown
    @output_path = output_path
  end

  def call
    Caracal::Document.save(@output_path) do |doc|
      doc.page_size { width 21_590; height 27_940 }
      doc.page_margins { top 1500; bottom 1500; left 1500; right 1500 }
      parse_lines(doc)
    end
  end

  private

  def parse_lines(doc)
    @markdown.each_line do |line|
      line = line.chomp
      if    line.start_with?("# ")  then doc.h1 line.sub("# ", "")
      elsif line.start_with?("## ") then doc.h2 line.sub("## ", "")
      elsif line.start_with?("### ") then doc.h3 line.sub("### ", "")
      elsif line.match?(/^[-*] /)   then doc.ul { li line.sub(/^[-*] /, "") }
      elsif line.strip.empty?       then doc.p ""
      else                               doc.p line
      end
    end
  end
end
