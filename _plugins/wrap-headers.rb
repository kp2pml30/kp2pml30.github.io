Jekyll::Hooks.register :documents, :post_render do |doc|
    next unless doc.output_ext == ".html"
    doc.output.gsub! /<\/h2>/, '</h2><section class="block">'
    doc.output.gsub! /<h2/, '</section><h2'
end
