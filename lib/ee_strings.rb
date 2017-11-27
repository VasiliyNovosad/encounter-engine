class String
  def upcase_utf8_cyr
    s = self.upcase
    ar = s.chars.map do |ch|
      case ch
        when "а" then "А"
        when "б" then "Б"
        when "в" then "В"
        when "г" then "Г"
        when "д" then "Д"
        when "е" then "Е"
        when "ё" then "Ё"
        when "ж" then "Ж"
        when "з" then "З"
        when "и" then "И"
        when "й" then "Й"
        when "к" then "К"
        when "л" then "Л"
        when "м" then "М"
        when "н" then "Н"
        when "о" then "О"
        when "п" then "П"
        when "р" then "Р"
        when "с" then "С"
        when "т" then "Т"
        when "у" then "У"
        when "ф" then "Ф"
        when "х" then "Х"
        when "ц" then "Ц"
        when "ч" then "Ч"
        when "ш" then "Ш"
        when "щ" then "Щ"
        when "ы" then "Ы"
        when "ъ" then "Ъ"
        when "ы" then "Ы"
        when "ь" then "Ь"
        when "э" then "Э"
        when "ю" then "Ю"
        when "я" then "Я"
        when "і" then "І"
        when "ї" then "Ї"
        when "є" then "Є"
        else ch
      end
    end

    ar.join
  end

  def downcase_utf8_cyr
    s = self.downcase
    ar = s.chars.map do |ch|
      case ch
        when "А" then "а"
        when "Б" then "б"
        when "В" then "в"
        when "Г" then "г"
        when "Д" then "д"
        when "Е" then "е"
        when "Ё" then "ё"
        when "Ж" then "ж"
        when "З" then "з"
        when "И" then "и"
        when "Й" then "й"
        when "К" then "к"
        when "Л" then "л"
        when "М" then "м"
        when "Н" then "н"
        when "О" then "о"
        when "П" then "п"
        when "Р" then "р"
        when "С" then "с"
        when "Т" then "т"
        when "У" then "у"
        when "Ф" then "ф"
        when "Х" then "х"
        when "Ц" then "ц"
        when "Ч" then "ч"
        when "Ш" then "ш"
        when "Щ" then "щ"
        when "Ъ" then "ъ"
        when "Ы" then "ы"
        when "Ь" then "ь"
        when "Э" then "э"
        when "Ю" then "ю"
        when "Я" then "я"
        when "І" then "і"
        when "Ї" then "ї"
        when "Є" then "є"
        else ch
      end
    end

    ar.join
  end
end
