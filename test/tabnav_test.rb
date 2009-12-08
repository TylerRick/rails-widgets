require File.dirname(__FILE__) + '/test_helper'

class TabnavTest < ActionView::TestCase

  include Widgets::TabnavHelper
  attr_accessor :params

  def setup
    @params = {}
  end

  def test_default_html_options
    tabnav = Widgets::Tabnav.new :sample
    assert_equal 'sample_tabnav', tabnav.html[:id]
    assert_equal 'sample_tabnav', tabnav.html[:class]
  end

  def test_highlights_on
    tabnav = create_tabnav :main do
      add_tab do |t|
        t.named 'first'
        t.links_to '/first'
      end
      add_tab do |t|
        t.named 'second'
        t.highlights_on({:controller => 'second'})
      end
      add_tab do |t|
        t.named 'third'
      end
    end

    @params = {:controller => 'second'}
    t = tabnav.highlighted_tab(params)
    assert_not_nil t
    assert_equal 'second', t.name

    render_tabnav tabnav

    #puts output_buffer
    root = HTML::Document.new(output_buffer).root
    assert_select root, "div[class='tabnav main_tabnav'][id=main_tabnav]:root", :count => 1 do
      assert_select 'ul[class="tabnav"]:only-of-type li', :count => 3 do
        assert_select 'li', :count => 3 do
          assert_select 'li[class=active]' do
            assert_select 'span', 'second'
          end
          assert_select 'li:nth-of-type(2)', 'second'
          assert_select 'li:nth-of-type(3)', 'third'
        end
      end
    end
  end

  def hash_for_tags_path(options = {})
    {:controller => :tags}.merge(options)
  end
  def test_highlights_not_on
    tabnav = create_tabnav :tags_index do
      add_tab do |t|
        t.named "My tags"
        t.titled t.name
        t.links_to          hash_for_tags_path
        t.highlights_not_on hash_for_tags_path(:all => true)
      end
      add_tab do |t|
        t.named "Everyone's tags"
        t.titled t.name
        t.links_to          hash_for_tags_path(:all => true)
      end
    end

    @params = hash_for_tags_path()
    t = tabnav.highlighted_tab(params)
    assert_not_nil t
    assert_equal "My tags", t.name

    @params = hash_for_tags_path(:all => true)
    t = tabnav.highlighted_tab(params)
    assert_not_nil t
    assert_equal "Everyone's tags", t.name
  end


  def test_content_below_tabnav
    tabnav = create_tabnav :main do
      add_tab do |t|
        t.named 'first'
      end
      add_tab do |t|
        t.named 'second'
      end
      add_tab do |t|
        t.named 'third'
      end
    end

    render_tabnav tabnav do
      concat content_tag('span') {'Some content for below the tabnav'}
    end

    #puts output_buffer
    root = HTML::Document.new(output_buffer).root
    assert_select root, "div[class='tabnav main_tabnav'][id=main_tabnav]:root", :count => 1 do
      assert_select 'ul:only-of-type li', :count => 3 do
        assert_select 'li:nth-of-type(1)', 'first'
      end
    end
    assert_select root, "div[class='tabnav_content main_tabnav_content'][id=main_tabnav_content]:root", :count => 1 do
      assert_select 'span', 'Some content for below the tabnav'
    end
  end

  def test_multiple_css_class
    create_tabnav :main do
      add_tab :html=>{:class=>'home'} do |t|
        t.named 'active-tab'
        t.links_to 'my/demo/link'
        t.highlight!
      end
      add_tab :html=>{:class=>'custom'} do |t|
        t.named 'second'
      end
      add_tab do |t|
        t.named 'middle'
      end
      add_tab :html=>{:class=>'last'} do |t|
        t.named 'disabled-tab'
        t.disable!
      end
    end
    render_tabnav @main_tabnav

    root = HTML::Document.new(output_buffer).root
    assert_select root, "div[class='tabnav main_tabnav'][id=main_tabnav]:root", :count => 1 do
      assert_select 'ul:only-of-type li', :count => 4 do
        assert_select 'li[class=home active]:first-of-type' do
          assert_select 'a[class=home active]:only-of-type', 'active-tab'
        end
        assert_select 'li.custom:nth-of-type(2)', 'second'
        assert_select 'li:nth-of-type(3)', 'middle'
        assert_select 'li[class=last disabled]:last-of-type' do
          assert_select 'span[class=last disabled]:only-of-type', 'disabled-tab'
        end
      end
    end
  end
end
