module Metadata
module PublicationGuesser
extend self

  # get these from wikipedia :|
  JOURNALS = ["Functional Programming", "the ACM", ]
  ACM_TRANSACTIONS = ["Graphics", "Computer-Human Interaction",]
  PUBLICATIONS = JOURNALS.map{|s|
    [/\bJournal of #{s}\b/, "Journal of #{s}"]
  } + ACM_TRANSACTIONS.map{|s|
    [/\bACM Transactions on #{s}\b/i, "ACM Transactions on #{s}"]
  } + [
    [/\bCommunications of the ACM\b/i, "Communications of the ACM"],
    [/\bCHI Letters\b/, "CHI Letters"]
  ]

  SIG_CONFERENCES = %w(ACT CHI MOD GRAPH PLAN)

  CONFERENCES = SIG_CONFERENCES.map{|s|
    [/\bSIG#{s}\b/, "SIG#{s}"]
  } + [
    [/\bCHI'\d\d\b/, "SIGCHI"],
    [/\bEuroGraphics[^a-zA-Z]/i, "EuroGraphics"],
    [/\bICFP[^a-zA-Z]/, "ICFP"],
    [/\bIPTPS[^a-zA-Z]/, "IPTPS"],
    [/\bPEPM[^a-zA-Z]/, "PEPM"],
    [/\bDocEng[^a-zA-Z]/, "DocEng"],
    [/\bUIST[^a-zA-Z]/, "UIST"],
    [/\bInt\. Symp\. on Smart Graphics\b/i, "Int. Symp. on Smart Graphics"]
  ]

  def find_publication(str)
    pubs = PUBLICATIONS.find_all{|p,n| str =~ p}
    pub = pubs[0]
    return pub if pub
    confs = CONFERENCES.find_all{|p,n| str =~ p}
    conf = confs[0]
    if conf && str =~ /\bin proceedings\b/i
      conf = conf.dup
      conf[1] = "In Proceedings of " + conf[1]
      return conf
    end
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
    return y.to_i if y and y.to_i <= (Time.now.year + 2)
    y = s.scan(/\b\d\d\b/)[0]
    return y.to_i + 1900 if y and y.to_i > 60
    ys = str.scan(/\b\d\d\d\d\b/)
    y = ys[-1]
    return y.to_i if y and y.to_i <= (Time.now.year + 2)
    y = ys[0]
    return y.to_i if y and y.to_i <= (Time.now.year + 2)
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
    publication = find_publication(str)
    publisher = find_publisher(str, publication)
    publish_time = find_publish_time(str, publication) if publication
    conference = find_conference(str)
    organizer = find_organizer(str, conference) if conference
    if conference
      year = find_year(str, conference)
      conference = conference.dup
      conference[1] = conference[1] + " #{year}" if year
    end
    h = {}
    h['Doc.PublishTime'] = Metadata.parse_time(publish_time.to_s) if publish_time
    h['Doc.Publication'] = publication[1] if publication
    h['Doc.Publisher'] = publisher[1] if publisher
    h['Event.Name'] = conference[1] if conference
    h['Event.Organizer'] = organizer[1] if organizer
    h
  end

end
end

