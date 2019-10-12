class IndexController < ApplicationController
  def index
    @page_content = "index,follow"
    @seo_block = create_index_seo_block
    coming_games = Game.notstarted
    current_games = Game.started - Game.finished.order(starts_at: :desc)
    render :index, locals: {
        current_games: current_games,
        coming_games: coming_games
    }
  end

  private

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

  def get_images(game_description)
    require 'nokogiri'
    doc = Nokogiri::HTML(game_description)
    doc.xpath('//img').map { |img| img['src'] }
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
    "name":"#{game.author_nickname}",
    "sameAs":"https://t.me/#{telegram_user(game.author_telegram) || 'questwtf'}"
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
