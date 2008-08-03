module Metadata
module TitleGuesser
extend self

  # higher the score, the more likely it is a title line
  LINE_SCORES = [
    [/^\s*\d*\.?\s*(abstract|introduction)\s*$/i, -100], # abstract | introduction
    [/^[^a-z]*\d+[^a-z]*$/i, -100], # number line
    [/\bhttp:\/\//, -100], # URL
    [/\b[a-z0-9]+@[a-z0-9]+\./i, -100], # email address
    [/\b(ACM|MIT|[uU]niversity|[cC]ollege|[iI]nstitute of|[Ss]chool)\b/, -100],
    [/^\s*\d*\.?\s*(addendum)\s*$/i, -20], # addendum

    [/^\s*.{0,5}\s*$/, -30], # very short line
    [/^\s*.{0,10}\s*$/, -20], # short line
    [/[^\n]{80}/, -20], # long line
    [/[^\n]{160}/, -40], # very long line
    [/[^\n]{320}/, -400], # very very long line
    [/^\s*[^A-Z]/, -100], # doesn't start with a capital letter
    [/^\s*[A-Z]+\s*$/, -5], # all uppercase
    [/[A-Z0-9:.,-_\s*+]/i, -15], # non-simple-character

    [/\b\d{4}\b/, -20], # year
    [/\d\d\d+/, -10], # several numbers
    [/\d/, -5], # number
    [/\./, -5], # period

    [/\.\s*$/, -10], # ends in period

    [/^\s*.{20,50}\s*$/, 10], # 20-50 characters
    [/\b(for|with|from|to|in)\b/i, 10], # uncommon in non-title
    [/\b(an|a)\b/i, 10], # uncommon in non-title
    [/\b(overview)\b/i, 10] # uncommon in non-title
  ]
  WORDS = {}
  File.read('/usr/share/dict/words').each_line{|l|
    WORDS[l.strip.downcase] = l.strip
  }

  def match_score(line)
    LINE_SCORES.inject(0){|score, (re, mod)|
      score += mod if line =~ re
      score
    }
  end

  def dict_score(line)
    words = line.split(/\s+/)
    sc = words.inject(0){|score, word|
      score -= 3 unless WORDS[word.downcase]
      score
    }
    if sc <= -1.5 * words.size
      sc -= 20
    end
    sc
  end

  def find_title_candidates(str)
    str = Metadata.remove_ligatures(
      str.split(/^\s*\d*\.\d*\s*(abstract|introduction)\s*$/i).first
    )
    lines = str.split(/\n+/)
    i = 30
    scored = lines.map{|line|
      line_score = match_score(line) + dict_score(line) + i
      i = i-10 if i > 0
      [line_score, line]
    }
    scored.sort.reverse
  end

  def guess_title(str)
    title = find_title_candidates(str).first
    title[1] if title
  end

end
end

