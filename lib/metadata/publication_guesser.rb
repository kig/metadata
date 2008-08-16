module Metadata
module PublicationGuesser
extend self

  module Genres
    CS = "Computer Science"
    FP = "Functional Programming"
    CHI = "Computer-Human Interaction"
    GFX = "Graphics"
    ALG = "Algorithms"
    TOC = "Theory of Computation"
    DM = "Data Management"
    PL = "Programming Languages"
  end

  # get these from wikipedia :|
  JOURNALS = [
    ["Functional Programming", [Genres::CS, Genres::FP]],
    ["the ACM", [Genres::CS]]
  ]
  ACM_TRANSACTIONS = [
    ["Graphics", [Genres::GFX]],
    ["Computer-Human Interaction",[Genres::CHI]]
  ]
  PUBLICATIONS = JOURNALS.map{|s,g|
    [/\bJournal of #{s}\b/, "Journal of #{s}", g]
  } + ACM_TRANSACTIONS.map{|s,g|
    [/\bACM Transactions on #{s}\b/i, "ACM Transactions on #{s}", [Genres::CS]+g]
  } + [
    [/\bCommunications of the ACM\b/i, "Communications of the ACM", [Genres::CS]],
    [/\bCHI Letters\b/, "CHI Letters", [Genres::CS, Genres::CHI]],
    [/\bLNCS|Lecture Notes in Computer Science\b/, "Lecture Notes in Computer Science", [Genres::CS]]
  ]

  SIG_CONFERENCES = [
    ["ACT", [Genres::ALG, Genres::TOC]],
    ["CHI", [Genres::CHI]],
    ["MOD", [Genres::DM]],
    ["GRAPH", [Genres::GFX]],
    ["PLAN", [Genres::PL]]
  ]

  CONFERENCES = SIG_CONFERENCES.map{|s,g|
    [/\bSIG#{s}\b/, "SIG#{s}", [Genres::CS]+g]
  } + [
    [/\bCHI'\d\d\b/, "SIGCHI", [Genres::CS, Genres::CHI]],
    [/\bEuroGraphics[^a-zA-Z]/i, "EuroGraphics", [Genres::CS, Genres::GFX]],
    [/\bICFP[^a-zA-Z]/, "ICFP", [Genres::CS, Genres::FP]],
    [/\bIPTPS[^a-zA-Z]/, "IPTPS"],
    [/\bPEPM[^a-zA-Z]/, "PEPM"],
    [/\bDocEng[^a-zA-Z]/, "DocEng"],
    [/\bUIST[^a-zA-Z]/, "UIST", [Genres::CS, Genres::CHI]],
    [/\bInt\. Symp\. on Smart Graphics\b/i, "Int. Symp. on Smart Graphics", [Genres::CS, Genres::GFX]]
  ]

  def find_publication(str)
    pubs = PUBLICATIONS.find_all{|p,n| str =~ p}
    pub = pubs[0]
    return pub if pub
    nil
  end

  def find_conference(str)
    confs = CONFERENCES.find_all{|p,n| str =~ p}
    conf = confs[0]
    return conf if conf
  end

  def find_publish_time(str, pub)
    s = str[str.index(pub[0]), 40]
    y = s.scan(/^[a-zA-Z\.\s]+['’](\d\d\d\d)\b/u).flatten[0]
    return y.to_i if y and y.to_i <= (Time.now.year + 2)
    y = s.scan(/^[a-zA-Z\.\s]+['’](\d\d)\b/u).flatten[0]
    return y.to_i + 1900 if y and y.to_i > 60
    return y.to_i + 2000 if y and (y.to_i + 2000) <= (Time.now.year + 2)
    y = s.scan(/\b\d\d\d\d\b/)[0]
    return y.to_i if y and y.to_i > 1960 and y.to_i <= (Time.now.year + 2)
    y = s.scan(/\b\d\d\b/)[0]
    return y.to_i + 1900 if y and y.to_i > 60
    ys = str.scan(/\b\d\d\d\d\b/)
    y = ys[-1]
    return y.to_i if y and y.to_i > 1960 and y.to_i <= (Time.now.year + 2)
    y = ys[0]
    return y.to_i if y and y.to_i > 1960 and y.to_i <= (Time.now.year + 2)
    nil
  end

  def find_year(str, pub)
    find_publish_time(str, pub)
  end

  def find_publisher(str, pub)
    nil
  end

  def find_organizer(str, conf)
    nil
  end

  def guess_pubdata(str)
    pages = str.strip.split(/\f+/)
    str = Metadata.remove_ligatures( pages.first )
    conference = find_conference(str)
    organizer = find_organizer(str, conference) if conference
    if conference
      year = find_year(str, conference)
      conference = conference.dup
      conference[1] = conference[1] + " #{year}" if year
    end
    publication = find_publication(str)
    if conference && !publication
      publication = conference.dup
      publication[1] = "In Proceedings of " + publication[1]
    end
    publisher = find_publisher(str, publication)
    publish_time = find_publish_time(str, publication) if publication
    h = {}
    h['Doc.PublishTime'] = Metadata.parse_time(publish_time.to_s) if publish_time
    h['Doc.Publication'] = publication[1] if publication
    h['Doc.Publisher'] = publisher[1] if publisher
    h['Doc.Genre'] = publication[2].join(", ") if publication and publication[2]
    h['Event.Name'] = conference[1] if conference
    h['Event.Organizer'] = organizer[1] if organizer
    h
  end

end
end

