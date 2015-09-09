#coding: utf-8

Plugin.create(:"mikutter-hide-tab") {
  UserConfig[:hide_tab_hidden_tabs] ||= []

  # GUI::TabからGtk::TabContainerを得る
  def get_tab_container(i_tab)
    i_timeline = i_tab.children[1] 

    if !i_timeline
      return nil
    end

    timeline = Plugin[:gtk].widgetof(i_timeline)

    tab_container = timeline.parent

    tab_container
  end

  # タブを隠す
  def hide_tab!(i_tab)
    hidden_tabs = UserConfig[:hide_tab_hidden_tabs].melt 
    hidden_tabs << i_tab.slug
    UserConfig[:hide_tab_hidden_tabs] = hidden_tabs.sort.uniq

    get_tab_container(i_tab).hide
  end

  # タブを再表示
  def show_tab!(i_tab)
    get_tab_container(i_tab).show

    hidden_tabs = UserConfig[:hide_tab_hidden_tabs].melt 
    hidden_tabs -= [i_tab.slug]
    UserConfig[:hide_tab_hidden_tabs] = hidden_tabs
  end

  # メニューアイテムを作成する
  def menuitem(menu, slug)
    i_tab = Plugin::GUI::Tab.cuscaded[slug]

    item = if i_tab.icon
      _ = Gtk::ImageMenuItem.new(i_tab.name)
      _.image = Gtk::WebIcon.new(i_tab.icon, 16, 16)
      _
    else
      Gtk::MenuItem.new(i_tab.name)
    end

    item.ssc(:activate) { |w, e|
      show_tab!(i_tab)

      menu.destroy
    }

    item
  end

  # 起動時処理
  on_boot { |service|
    if Service.primary == service
      # Delayerは初期化が終わった後に実行され始める法則を利用して、前回のタブ隠し状況を復元する
      Delayer.new {
        # 存在しないタブの情報を消す
        UserConfig[:hide_tab_hidden_tabs] = UserConfig[:hide_tab_hidden_tabs].select { |_| Plugin::GUI::Tab.cuscaded[_] }

        # タブを隠し直す
        UserConfig[:hide_tab_hidden_tabs].each { |slug|
          i_tab = Plugin::GUI::Tab.cuscaded[slug]
          hide_tab!(i_tab)
        }
      }
    end
  }

  # タブを隠す
  command(:hide_tab,
          :name => _("タブを隠す"),
          :condition => lambda { |opt| !opt.widget.temporary_tab? },
          :visible => true,
          :role => :tab) { |opt|
    hide_tab!(opt.widget)
  }

  # タブを再表示
  command(:show_tab,
          :name => _("タブを再表示"),
          :condition => lambda { |opt| true },
          :icon => Skin.get("etc.png"),
          :visible => true,
          :role => :window) { |opt|

    menu = nil

    UserConfig[:hide_tab_hidden_tabs].each { |slug|
      menu ||= Gtk::Menu.new

      item = menuitem(menu, slug)
      menu.append(item)
    } 

    if menu
      menu.show_all
      menu.popup(nil, nil, 0, 0)
    end
  }
}
