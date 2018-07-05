class GamesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :find_game, except: [:index, :new, :create]
  before_action :ensure_game_was_not_finished, only: [:edit, :update, :destroy]
  before_action :find_team, only: [:show]
  before_action :ensure_author_if_game_is_draft, only: [:show]
  before_action :ensure_author_if_no_start_time, only: [:show]
  before_action :ensure_author, only: [:edit, :update]
  before_action :max_team_number_from_nz, only: [:update]
  before_action :ensure_author_if_no_finish_time, only: [:show_scenario]
  before_action :find_teams, only: [:show, :new_level_order]

  def index
    @page_content = "index,follow"
    if params[:user_id].blank?
      @games = Game.non_drafts
    else
      user = User.find(params[:user_id])
      @games = user.created_games
    end
    @seo_block = create_index_seo_block
    render
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new(game_params)
    @game.author = current_user
    @authors = User.where(id: params[:organizing_team])
    @game.authors << @authors
    if @game.save
      redirect_to game_path(@game)
    else
      render 'new'
    end
  end

  def show
    if request.path != game_path(@game)
      return redirect_to @game, :status => :moved_permanently
    end
    @page_title = "#{@game.name} ᐈ【 Квести Луцьк 】"
    @page_description = "❰❰❰ #{@game.name} ❱❱❱ #{@game.small_description && @game.small_description != '' ? @game.small_description : "це: ➔ цікаві логічні завдання від кращих авторів Луцька, ➔ захоплюючі пошуки, ➔ драйв та адреналін, ➔ неймовірні пригоди та яскраві емоції, ➔ новий формат інтелектуально-активного відпочинку! ➤ Якщо ти рухаєш мізками та дупою швидше ніж твоя бабуся, ПРИЄДНУЙСЯ"} ➤【 Квест 🔍 Луцьк 】"
    @page_content = "index,follow"
    @teams_for_test = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
    @game_entries = GameEntry.of_game(@game).with_status('new')
    @levels = @game.levels
    @topic = Forem::Topic.find(@game.topic_id) unless @game.topic_id.nil?
    @seo_block = create_show_seo_block
    render
  end

  def edit
    render
  end

  def update
    @authors = User.where(id: params[:organizing_team])
    @game.authors.destroy_all
    @game.authors << @authors
    if @game.update_attributes(game_params)
      redirect_to game_path(@game)
    else
      render 'edit'
    end
  end

  def delete
    @game.destroy
    redirect_to dashboard_path
  end

  def destroy
    @game.levels.each(&:destroy)
    @game.destroy
    redirect_to dashboard_path
  end

  def end_game
    @game.finish_game!
    game_passings = GamePassing.of_game(@game)
    game_passings.each(&:end!)
    redirect_to dashboard_path
  end

  def start_test
    game = find_game
    # game.is_draft = 'f'
    game.is_testing = 't'
    game.test_date = game.starts_at
    game.starts_at = Time.zone.now + 0.1.second
    game.registration_deadline = nil
    game.tested_team_id = params[:team_id]
    game.save!
    sleep(rand(1))

    redirect_to game_path(@game)
  end

  def finish_test
    game = find_game
    # game.is_draft = 't'
    game.is_testing = 'f'
    game.starts_at = game.test_date
    game.test_date = Time.zone.now
    game.tested_team_id = nil
    game.save!

    game_passing = GamePassing.of_game(game)
    logs = Log.of_game(game)
    game_bonuses = GameBonus.of_game(game)

    game_passing.delete_all
    logs.delete_all
    game_bonuses.delete_all

    redirect_to game_path(@game)
  end

  def show_scenario
  end

  def new_level_order
    @levels = @game.levels
    @level_orders = {}
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
    (1..@levels.count).each do |index|
      levels = {}
      @teams.each do |team|
        ordered_level = LevelOrder.of(@game, team).where(position: index).first
        new_level = @levels.where(position: index).first
        levels[team.id] = (ordered_level.nil? ? new_level.id : ordered_level.level_id)
      end
      @level_orders[index] = levels
    end
    render
  end

  def create_level_order
    @levels = @game.levels
    @teams = GameEntry.of_game(@game).where("status in ('new', 'accepted')").map{ |game_entry| game_entry.team }
    (1..@levels.count).each do |index|
      @teams.each do |team|
        selected_level = params["level_id_#{index}_#{team.id}"]
        level_order = LevelOrder.where(game_id: @game.id, team_id: team.id, position: index).first
        if level_order.nil?
          level_order = LevelOrder.create!(game_id: @game.id, team_id: team.id, level_id: selected_level, position: index)
        else
          level_order.update!(game_id: @game.id, team_id: team.id, level_id: selected_level, position: index)
        end
      end
    end
    redirect_to game_path(@game)
  end

  protected

  def game_params
    params.require(:game).permit(
      :name, :description, :game_type, :duration, :starts_at,
      :registration_deadline, :max_team_number, :is_draft,
      :is_testing, :author, :test_date, :tested_team_id, :game_size,
      :price, :place, :city, :small_description, :image
    )
  end

  def find_game
    @game = Game.friendly.find(params[:id])
  end

  def game_is_draft?
    @game.draft?
  end

  def find_team
    @team = current_user ? current_user.team : nil
  end

  def find_teams
    @accepted_game_entries = GameEntry.of_game(@game).with_status('accepted')
  end

  def no_start_time?
    @game.starts_at.nil?
  end

  def no_finish_time?
    @game.author_finished_at.nil?
  end

  def ensure_author_if_game_is_draft
    ensure_author if game_is_draft?
  end

  def ensure_author_if_no_start_time
    ensure_author if no_start_time?
  end

  def ensure_author_if_no_finish_time
    ensure_author if no_finish_time?
  end

  def max_team_number_from_nz
    @game.max_team_number = 10_000 if @game.max_team_number.nil? || @game.max_team_number.equal?(0)
  end

  def create_index_seo_block
    coming_games = Game.order(:starts_at).notstarted
    %{
<script type="application/ld+json">
  {
  "@context":"http://schema.org",
  "@type":"Organization",
  "name":"【 Квести Луцьк 】 ᐈ QUEST.wtf",
  "description":"❰❰❰ QUEST Луцьк ❱❱❱ ℚ - цікаві логічні завдання від кращих авторів Луцька, ℚ - захоплюючі пошуки, ℚ - драйв та адреналін, ℚ - неймовірні пригоди та яскраві емоції, ℚ - новий формат інтелектуально-активного відпочинку! ➤ Якщо ти рухаєш мізками та дупою швидше ніж твоя бабуся, ПРИЄДНУЙСЯ 【 Квести Луцьк 】 ᐈ QUEST.wtf",
  "logo":"https://quest.wtf#{ActionController::Base.helpers.asset_path 'quest_wtf_logo.png'}",
  "url":"https://quest.wtf",
  "sameAs":[
    "https://www.facebook.com/questwtflutsk/",
    "https://www.facebook.com/groups/2019251521639524/",
    "https://t.me/questwtf"
    ],
  "founder": {
    "@type":"person",
    "name":"Новосад Василь",
    "sameAs":"Fr1end",
    "url":"https://t.me/Fr1end_w0lf"
    },
  "contactPoint": [
    {
      "@type":"ContactPoint",
      "contactType":"technical support",
      "name":"ОРГ проекту QUEST.wtf",
      "sameAs":"Новосад Василь",
      "telephone":"+38(050)378-48-31"
      },
    {
      "@type":"ContactPoint",
      "contactType":"customer support",
      "name":"Quest-спільнота Луцька",
      "url":"https://t.me/questwtf"
      }
    ]
  }
</script>
<script type="application/ld+json">
  {
  "@context":"http://schema.org",
  "@type":"BreadcrumbList",
  "itemListElement":[
    {
      "@type":"ListItem",
      "position":1,
      "item":{
        "@id":"https://quest.wtf",
        "name":"Quest.wtf"
        }
      },
    {
      "@type":"ListItem",
      "position":2,
      "item":{
        "@id":"https://quest.wtf/#",
        "name":"Квест 🔍 Луцьк"
        }
      }
    ]
  }
</script>
<script type="application/ld+json">
[#{coming_games.map { |game| get_game_seo_block(game) }.join(',')}]
</script>
    }
  end

  def create_show_seo_block
    images = get_images(@game.description)
    %{
<script type="application/ld+json">
  {
  "@context":"http://schema.org",
  "@type":"BreadcrumbList",
  "itemListElement":[
    {
      "@type":"ListItem",
      "position":1,
      "name":"Quest.wtf"
      },
    {
      "@type":"ListItem",
      "position":2,
      "name":"QL 🔍 "
      },
    {
      "@type":"ListItem",
      "position":3,
      "item":{
        "@id":"#{game_url(@game)}",
        "name":"#{@game.name}"
        }
      }
    ]
  }
</script>
<script type="application/ld+json">
  #{get_game_seo_block(@game)}
</script>
    }
  end

  def get_images(game_description)
    require 'nokogiri'
    doc = Nokogiri::HTML(game_description)
    doc.xpath("//img").map { |img| img['src'] }
  end

  def telegram_user(telegram)
    if telegram.nil? || telegram == ''
      nil
    else
      telegram[0] == '@' ? telegram[1..-1] : telegram
    end
  end

  def get_game_seo_block(game)
    images = get_images(game.description)
    %{
    {
  "@context":"http://schema.org",
  "@type":"Event",
  "name":"#{game.name}",
  "description":"#{game.small_description && game.small_description != '' ? game.small_description : game.name}",
  #{!game.image.nil? || (images.length > 0) ? "\"image\": \"#{game.image.nil? || game.image == '' ? images[0] : game.image}\"," : ''}
  "performer": {
    "@type":"Person",
    "name":"#{game.author.nickname}",
    "sameAs":"https://t.me/#{telegram_user(game.author.telegram) || 'questwtf'}"
    },
  "startDate":"#{game.starts_at}",
  "endDate":"2018",
  "location":{
    "@type":"Place",
    "name":"#{game.place && game.place != '' ? game.place : 'Центр, біля Бім-Бома'}",
    "address":{
      "@type":"PostalAddress",
      "addressLocality":"#{game.city && game.city != '' ? game.city : 'Луцьк'}"
      }
    },
  "offers": {
    "@type":"Offer",
    "url":"#{game_url(game)}",
    "price":"#{game.price || 100}",
    "priceCurrency":"UAH",
    "availability":"http://schema.org/InStock",
    "validFrom":"2018"
    }
  }
    }
  end
end
