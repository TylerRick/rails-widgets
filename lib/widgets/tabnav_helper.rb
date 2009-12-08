module Widgets
  module TabnavHelper
    protected

#    def tabnav name, opts={}, &block
#      partial_template = opts[:partial] || "widgets/#{name}_tabnav"
#      html = capture { render :partial => partial_template }
#      if block_given?
#        options = {:id => @_tabnav.html[:id] + '_content', :class => @_tabnav.html[:class] + '_content'}
#        html << tag('div', options, true)
#        html << capture(&block)
#        html << '</div>'
#        concat html
#        nil # avoid duplication if called with <%= %>
#      else
#        return html
#      end
#    end


    # Renders a tabnav.
    #
    # Example:
    # <%
    # main_tabnav = create_tabnav() do
    #   add_tab do |t|
    #     t.named 'first'
    #     t.links_to '/first'
    #   end
    # end
    # %>
    # <% render_tabnav main_tabnav do %>
    #   ...html...
    # <% end %>
    #
    # or <%= render_tabnav main_tabnav %>
    #
    def render_tabnav(tabnav, opts={}, &block)
      concat tabnav.render_css('tabnav') if tabnav.generate_css?

      html = tabnav.html.dup
      classes = html[:class].split(' ')
      html[:class] = (['tabnav'] + classes).join(' ')
      html[:id] ||= classes.first
      concat tag('div', html, true) + "\n"
        tabnav.sort! if opts[:sort] == true
        render_tabnav_tabs
      concat "</div>\n"

      if block_given?
        options = {:id => @_tabnav.html[:id] + '_content', :class => "tabnav_content #{classes.first + '_content'}"}
        concat(content_tag('div', options) {
          capture(&block)
        })
        nil # avoid duplication if called with <%= %>
      else
        nil
        #return html
      end
    end

    def tabnav_with_contents tabnav, &block
      raise ArgumentError, "Missing block" unless block_given?
      render_tabnav(tabnav) {}
    end

    #-----------------------------------------------------------------------------------------------
    # tabnav building methods

    # Creates a new tabnav, which can be rendered with render_tabnav.
    #
    # Returns the newly created tabnav and also stores it in an instance variable nameed "{name}_tabnav".
    #
    # Sometimes it is useful to be able to create a tabnav in a separate step, without rendering it immediately.
    # For example, you can query the tabnav to see which tab is highlighted and show different content
    # (such as a different sub-tabnav) depending on the active tab. This keeps things DRY.
    #
    # Example:
    #   if @main_tabnav.highlighted_tab._?.name == 'Settings'
    #     ...
    #   end
    #
    # options
    # ===
    #   :partial: defaults to widgets/<name>_tabnav
    #
    def create_tabnav(name, opts={}, &proc)
      raise ArgumentError, "Missing name parameter in tabnav call" unless name
      raise ArgumentError, "Missing block in tabnav call" unless block_given?
      @_tabnav = Tabnav.new(name, opts)
      @_binding = proc.binding # the binding of calling page

      instance_eval(&proc)

      instance_variable_set("@#{name}_tabnav", @_tabnav)
    end

    def add_tab options = {}, &block
      raise 'Cannot call add_tab outside of a render_tabnav block' unless @_tabnav
      @_tabnav.tabs << Tab.new(options, &block)
      nil
    end

    # inspects controller names
    def controller_names
      files = Dir.entries(File.join(RAILS_ROOT, 'app/controllers'))
      controllers = files.select {|x| x.match '_controller.rb'}
      return controllers.map {|x| x.sub '_controller.rb', ''}.sort
    end

    private

    # renders the tabnav's tabs
    def render_tabnav_tabs
      return if @_tabnav.tabs.empty?

      concat tag('ul', {:class => 'tabnav'} , true)

      @_tabnav.tabs.each do |tab|
        li_options = {}
        li_options[:id] = "#{tab.html[:id]}_container" if tab.html[:id]

        tab_html = tab.html.dup
        tab_html[:class] ||= ''
        if tab.disabled?
          tab_html[:class] << ' ' unless tab_html[:class].blank?
          tab_html[:class] << 'disabled'
        elsif tab.highlighted?(params)
          tab_html[:class] << ' ' unless tab_html[:class].blank?
          tab_html[:class] << 'active'
        end
        li_options[:class] = tab_html[:class]

        concat tag('li', li_options, true)
        if tab.disabled? || (tab.link.empty? && tab.remote_link.nil?)
          concat content_tag('span', tab.name, tab_html)
        elsif !tab.link.empty?
          concat link_to(tab.name, tab.link, tab_html)
        elsif tab.remote_link
          success = "document.getElementsByClassName('active', $('" + @_tabnav.html[:id]+ "')).each(function(item){item.removeClassName('active');});"
          success += "$('#{tab.html[:id]}').addClassName('active');"
          # success += "alert(this);"

          remote_opts = {:update => @_tabnav.html[:id] + '_content',
            # :success => success,
            :method => :get,
            :loading => loading_function + success,
            :loaded => "$('#{@_tabnav.html[:id]}_content').setStyle({height: 'auto'});"
          }
          concat link_to_remote(tab.name, remote_opts.merge(tab.remote_link), tab_html)
        else
          raise "Unexpected condition"
        end
        concat "</li>\n"
      end
      concat '</ul>'
    end

    # generate javascript function to use
    # while loading remote tabs
    # NB: EXPERIMENTAL
    def loading_function
      # show customized partial and adjust content height
      # todo: find out why I need a 38px offset :-|
      begin
        inner_html = capture {render :partial => 'shared/tabnav_loading' }
      rescue
        inner_html = "Loading..."
      end
      return <<-JAVASCRIPT
          var element = $('#{@_tabnav.html[:id]}_content');
          var h = element.getHeight() - 38;
          element.innerHTML='#{escape_javascript(inner_html)}';
          element.setStyle({height: ''+h+'px'});
          //element.morph('height:'+h+'px');
      JAVASCRIPT
    end
  end
end
