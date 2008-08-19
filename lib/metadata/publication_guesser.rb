require 'metadata/title_guesser'

module Metadata
module PublicationGuesser
extend self

  module Topics
    SCIENCE = "Science"
    ASTRO = "Astronomy"
    ASTROPHYS = "Astrophysics"
    BIOLOGY = "Biology"
      AGRICULTURE = "Agriculture"
      ANATOMY = "Anatomy"
      BIOCHEM = "Biochemistry"
      BIOPHYSICS = "Biophysics"
      BIOINFO = "Bioinformatics"
      NEUROSCI = "Neuroscience"
      VIROLOGY = "Virology"
    CHEMISTRY = "Chemistry"
    CS = "Computer Science"
      FP = "Functional Programming"
      ML = "Machine Learning"
      CHI = "Computer-Human Interaction"
      GFX = "Graphics"
      ALG = "Algorithms"
      TOC = "Theory of Computation"
      DM = "Data Management"
      PL = "Programming Languages"
    ENG = "Engineering"
      BIOMED = "Biomedical Engineering"
      CHEMENG = "Chemical Engineering"
      ENVENG = "Environmental Engineering"
      ELEENG = "Electrical Engineering"
      HYDENG = "Hydrologic Engineering"
    GEOPHYS = "Geophysics"
      EARTHSCI = "Earth Science"
      HYDROLOGY = "Hydrology"
      GEOCHEM = "Geochemistry"
      MINERALOGY = "Mineralogy"
      GEOLOGY = "Geology"
      OCEANOGRAPHY = "Oceanography"
      GLACIOLOGY = "Glaciology"
      ATMOSPHERE = "Atmospheric Science"
    MATH = "Mathematics"
    MEDICINE = "Medicine"
      ALLERGY = "Allergy"
      ANESTHESIOLOGY = "Anesthesiology"
      PHARSCI = "Pharmaceutical Sciences"
      PSYCHIATRY = "Psychiatry"
      TOXICOLOGY = "Toxicology"
    PHYSICS = "Physics"
      ACOUSTICS = "Acoustics"
      PLASMA = "Plasma Physics"
      MEASUREMENT = "Measurement"
      NUCLEAR = "Nuclear Physics"
      OPTICS = "Optics"
      MATERIALS = "Materials Science"
      LOWTEMP = "Low Temperature Physics"
      CHEMPHYS = "Chemical Physics"
      SOFTMATPHYS = "Soft Matter Physics"
      MEDPHYS = "Medical Physics"
      BIOPHYS = "Biological Physics"
      STATPHYS = "Statistical Physics"
      THEOPHYS = "Theoretical Physics"
    STATISTICS = "Statistics"
  end

  JOURNALS = []

  # Astronomy
  JOURNALS.push(*( [
    ["Acta Astronomica", []],
    ["Advances in Space Research", []],
    ["Annual Review of Astronomy and Astrophysics", []],
    ["Annual Review of Earth and Planetary Sciences", []],
    ["Apeiron", []],
    ["Astronomical Journal", []],
    ["Astronomy & Astrophysics", []],
    ["Astroparticle Physics", []],
    ["Astrophysical Journal", []],
    ["Astrophysics and Space Science", []],
    ["Baltic Astronomy", []],
    ["Bulletin of the ASI", []],
    ["Bulletin of the Vilnius Astronomical Observatory", []],
    ["Chinese Astronomy", []],
    ["Icarus", []],
    ["Journal of Astrophysics & Astronomy", []],
    ["Journal of Cosmology and Astroparticle Physics", []],
    ["Monthly Notices of the Royal Astronomical Society", []],
    ["New Astronomy", []],
    ["New Astronomy Review", []],
    ["Publications of the Astronomical Society of Japan", []],
    ["Publications of the Astronomical Society of the Pacific", []],
    ["Revista Mexicana de Astronomia y Astrofisica", []],
    ["Space Journal", []],
    ["Vistas in Astronomy", []]
  ].map{|a| a[-1] = [Topics::ASTRO, Topics::ASTROPHYS]+a[-1]; a }))

  # Biology
  JOURNALS.push(*( [
    ["African Invertebrates", []],
    ["American Journal of Botany", []],
    ["American Midland Naturalist", []],
    ["American Naturalist", []],
    ["Annual Review of Ecology, Evolution, and Systematics", []],
    ["Annual Review of Genetics", []],
    ["Annual Review of Genomics and Human Genetics", []],
    ["Annual Review of Microbiology", []],
    ["Annual Review of Physiology", []],
    ["Annual Review of Plant Biology", []],
    ["BioEssays", []],
    ["Biological Reviews", []],
    ["Biology Letters", []],
    ["Biology of Reproduction", []],
    ["Biometrika", []],
    ["Bioscience", []],
    ["Biotropica", []],
    ["Canadian Journal of Forest Research", []],
    ["Cell", []],
    ["Central European Journal of Biology", []],
    ["Disease Models & Mechanisms", []],
    ["Ecological Applications", []],
    ["Ecological Monographs", []],
    ["Ecology", []],
    ["Ecology Letters", []],
    ["Emu", []],
    ["European Journal of Human Genetics", []],
    ["Evolution", []],
    ["Evolution and Development", []],
    ["Evolutionary Ecology", []],
    ["Evolutionary Ecology Research", []],
    ["Faseb Journal", []],
    ["Forest Ecology and Management", []],
    ["Functional Ecology", []],
    ["Genetica", []],
    ["Genetics", []],
    ["Genome Biology", []],
    ["Genome Research", []],
    ["Heredity", []],
    ["International Journal of Biological Sciences", []],
    ["International Journal of Biometeorology", []],
    ["Journal of Applied Ecology", []],
    ["Journal of Animal Ecology", []],
    ["Journal of Ecology", []],
    ["Journal of Evolutionary Biology", []],
    ["Journal of Experimental Biology", []],
    ["Journal of Herpetology", []],
    ["Journal of Mammology", []],
    ["Journal of Molluscan Studies", []],
    ["Journal of Natural History", []],
    ["Journal of Theoretical Biology", []],
    ["Journal of Zoology", []],
    ["Molecular Biology", []],
    ["Molecular Biology and Evolution", []],
    ["Molecular Phylogenetics and Evolution", []],
    ["Molecular Systems Biology", []],
    ["Nature Protocols", []],
    ["Nature Reviews Cancer", []],
    ["Nature Reviews Drug Discovery", []],
    ["Nature Reviews Genetics", []],
    ["Nature Reviews Immunology", []],
    ["Nature Reviews Microbiology", []],
    ["Nature Reviews Molecular Cell Biology", []],
    ["Oecologia", []],
    ["Oikos", []],
    ["Phytochemistry", []],
    ["Plant Physiology", []],
    ["PLoS Biology", []],
    ["Quarterly Review of Biology", []],
    ["Rejuvenation Research", []],
    ["Theoretical Biology and Medical Modelling", []],
    ["Theoretical Population Biology", []],
    ["Trends in Cell Biology", []],
    ["Trends in Ecology and Evolution", []],
    ["Trends in Genetics", []],
    ["Wetlands", []]
  ].map{|a| a[-1] = [Topics::BIOLOGY]+a[-1]; a }))
  # Agriculture
  JOURNALS.push(*( [
    ["Animal Production", []],
    ["Annales de Zootechnie", []],
    ["Applied Animal Behavioral Science", []],
    ["Crop Science", []],
    ["Domestic Animal Endocrinology", []],
    ["Genetic Selection Evolution", []],
    ["Journal of Animal Science", []],
    ["Journal Dairy Research", []],
    ["Journal of Dairy Science", []],
    ["Journal of Food Science", []],
    ["Livestock Production Science", []],
    ["Livestock Science", []],
    ["Poultry Science", []],
    ["Worlds Poultry Science Journal", []]
  ].map{|a| a[-1] = [Topics::BIOLOGY, Topics::AGRICULTURE]+a[-1]; a }))
  # Anatomy
  JOURNALS.push(*( [
    ["Advances in Anatomy, Embryology and Cell Biology", []],
    ["American Journal of Anatomy", []],
    ["Anatomical Record", []],
    ["Anatomy and Embryology", []],
    ["Applied Immunohistochemistry & Molecular Morphology", []],
    ["Cells Tissues Organs", []],
    ["Developmental Dynamics", []],
    ["Journal of Anatomy", []],
    ["Journal of Craniofacial Genetics and Developmental Biology", []],
    ["Journal of Morphology", []],
    ["Journal of Pineal Research", []],
    ["Microscopy Research and Technique", []],
    ["Virchows Archiv - A", []],
    ["Zoomorphology", []]
  ].map{|a| a[-1] = [Topics::BIOLOGY, Topics::ANATOMY]+a[-1]; a }))
  # Biochemistry
  JOURNALS.push(*( [
    ["Annual Review of Biochemistry", []],
    ["Biochemica et Biophysica Acta", []],
    ["Biochemical and Biophysical Research Communications", []],
    ["Biochemical Journal", []],
    ["Biochemical Society Transactions", []],
    ["Biochemistry", []],
    ["Biotechnology and Applied Biochemistry", []],
    ["FEBS Journal", []],
    ["FEBS Letters", []],
    ["Journal of Biochemistry", []],
    ["Journal of Biological Chemistry", []],
    ["Methods in Enzymology", []],
    ["Molecular and Cellular Biochemistry", []],
    ["Nucleic Acids Research", []],
    ["Trends in Biochemistry", []]
  ].map{|a| a[-1] = [Topics::BIOLOGY, Topics::BIOCHEM]+a[-1]; a }))
  # Bioinformatics
  JOURNALS.push(*( [
    ["Applied Bioinformatics", []],
    ["BMC Bioinformatics", []],
    ["Briefings in Bioinformatics", []],
    ["Cancer Informatics", []],
    ["Evolutionary Bioinformatics", []]
  ].map{|a| a[-1] = [Topics::BIOLOGY, Topics::BIOINFO]+a[-1]; a }))
  # Biophysics
  JOURNALS.push(*( [
    ["Annual Review of Biophysics and Biomolecular Structure", []],
    ["Biochemica et Biophysica Acta", []],
    ["Biophysical Journal", []],
    ["FEBS Letters", []],
    ["Journal of Structural Biology", []],
    ["Neurosignals", []],
    ["Progress in Biophysics & Molecular Biology", []],
    ["Quarterly Reviews in Biophysics", []],
    ["Structure", []]
  ].map{|a| a[-1] = [Topics::BIOLOGY, Topics::BIOPHYSICS]+a[-1]; a }))
  # Neuroscience
  JOURNALS.push(*( [
    ["Genes, Brain and Behavior", []],
    ["Nature Reviews Neuroscience", []],
    ["Neurogenetics", []],
    ["Neuron", []],
  ].map{|a| a[-1] = [Topics::BIOLOGY, Topics::NEUROSCI]+a[-1]; a }))
  # Virology
  JOURNALS.push(*( [
    ["Acta Virologica", []],
    ["Advances in Virus Research", []],
    ["AIDS", []],
    ["AIDS Care", []],
    ["AIDS Research and Human Retroviruses", []],
    ["Antiviral Chemistry & Chemotherapy", []],
    ["Antiviral Research", []],
    ["Antiviral Therapy", []],
    ["Archives of Virology", []],
    ["Herpes", []],
    ["International Journal of STD and AIDS", []],
    ["Intervirology", []],
    ["Journal of Acquired Immune Deficiency Syndromes", []],
    ["Journal of Clinical Virology", []],
    ["Journal of General Virology", []],
    ["Journal of Human Virology", []],
    ["Journal of Medical Virology", []],
    ["Journal of Neurovirology", []],
    ["Journal of Viral Hepatitis", []],
    ["Journal of Virology", []],
    ["Journal of Virological Methods", []],
    ["Monographs in Virology", []],
    ["Papillomavirus Report", []],
    ["Retrovirology", []],
    ["Reviews in Medical Virology", []],
    ["Topics in HIV Medicine", []],
    ["Viral Hepatitis", []],
    ["Viral Immunology", []],
    ["Virology", []],
    ["Virology Journal", []],
    ["Virus Genes", []],
    ["Virus Research", []]
  ].map{|a| a[-1] = [Topics::BIOLOGY, Topics::VIROLOGY]+a[-1]; a }))


  # Chemistry
  JOURNALS.push(*( [
    ["Accounts of Chemical Research", []],
    ["Acta Chemica Scandinavica", []],
    ["Acta Crystallographica, Section E, Structure Reports online", []],
    ["Advanced Functional Materials", []],
    ["Advanced Synthesis and Catalysis", []],
    ["Advances in Catalysis", []],
    ["Advances in Organometallic Chemistry", []],
    ["Aldrichimica Acta", []],
    ["The Analyst", []],
    ["Analytical and Bioanalytical Chemistry", []],
    ["Analytical Biochemistry", []],
    ["Analytical Chemistry", []],
    ["Angewandte Chemie International Edition", []],
    ["Annual Reports Section A of the Royal Society of Chemistry", []],
    ["Annual Reports Section B of the Royal Society of Chemistry", []],
    ["Annual Reports Section C of the Royal Society of Chemistry", []],
    ["Annual Review of Physical Chemistry", []],
    ["Applied Organometallic Chemistry", []],
    ["Applied Spectroscopy", []],
    ["Arkivoc", []],
    ["Australian Journal of Chemistry", []],
    ["Australian Journal of Education in Chemistry", []],
    ["Beilstein Journal of Organic Chemistry", []],
    ["Biochemical Journal", []],
    ["Bioconjugate Chemistry", []],
    ["Bioelectrochemistry", []],
    ["Biomacromolecules", []],
    ["Bioorganic and Medicinal Chemistry", []],
    ["Bioorganic and Medicinal Chemistry Letters", []],
    ["Bulletin of the Chemical Society of Japan", []],
    ["Canadian Journal of Chemistry", []],
    ["Catalysis Communications", []],
    ["Catalysis Reviews", []],
    ["Catalysts and Catalysed Reactions", []],
    ["Ceramics-Silikaty", []],
    ["ChemBioChem", []],
    ["Chemical Communications", []],
    ["Chemical Physics", []],
    ["Chemical Physics Letters", []],
    ["Chemical Reviews", []],
    ["Chemical Society Reviews", []],
    ["Chemische Berichte", []],
    ["Chemistry Education Research and Practice", []],
    ["Chemistry: A European Journal", []],
    ["Chemistry: An Asian Journal", []],
    ["Chemistry Letters", []],
    ["Chemistry of Materials", []],
    ["ChemMedChem", []],
    ["ChemPhysChem", []],
    ["Collection of Czechoslovak Chemical Communications", []],
    ["Comptes rendus Chimie", []],
    ["Computers and Chemistry", []],
    ["Coordination Chemistry Reviews", []],
    ["CrystEngComm", []],
    ["Chemistry & Biodiversity", []],
    ["Dalton Transactions", []],
    ["Education in Chemistry", []],
    ["Electrochemistry Communications", []],
    ["Electroanalysis", []],
    ["Electrochimica Acta", []],
    ["Environmental Chemistry", []],
    ["European Journal of Inorganic Chemistry", []],
    ["European Journal of Medicinal Chemistry", []],
    ["European Journal of Organic Chemistry", []],
    ["European Polymer Journal", []],
    ["Faraday Discussions", []],
    ["Faraday Transactions", []],
    ["Geochemical Transactions", []],
    ["Green Chemistry", []],
    ["Helvetica Chimica Acta", []],
    ["Inorganic and Nuclear Chemistry Letters", []],
    ["Inorganic Chemistry Communications", []],
    ["Inorganic Chemistry", []],
    ["Inorganica Chimica Acta", []],
    ["International Journal of Hydrogen Energy", []],
    ["International Journal of Molecular Sciences", []],
    ["International Journal of Quantum Chemistry", []],
    ["International Reviews in Physical Chemistry", []],
    ["Internet Electronic Journal of Molecular Design", []],
    ["Ion Exchange Letters", []],
    ["JAAS Journal of Analytical Atomic Spectrometry", []],
    ["Journal of Agricultural and Food Chemistry", []],
    ["Journal of the American Chemical Society", []],
    ["Journal of Applied Polymer Science", []],
    ["Journal of Biological Chemistry", []],
    ["Journal of Biological Inorganic Chemistry", []],
    ["Journal of the Brazilian Chemical Society", []],
    ["Journal of Catalysis", []],
    ["Journal of Chemical Education", []],
    ["Journal of Chemical Information and Modeling", []],
    ["Journal of Chemical Physics", []],
    ["Journal of Chemical Research", []],
    ["Journal of the Chemical Society", []],
    ["Journal of Chromatography, A", []],
    ["Journal of Cluster Science", []],
    ["Journal of Combinatorial Chemistry", []],
    ["Journal of Computational Chemistry", []],
    ["Journal of Electroanalytical Chemistry", []],
    ["Journal of the Electrochemical Society", []],
    ["Journal of Environmental Monitoring", []],
    ["Journal of Fluorescence", []],
    ["Journal of Inorganic and Nuclear Chemistry - see Polyhedron", []],
    ["Journal of Inorganic Biochemistry", []],
    ["Journal of Macromolecular Science, Part A Pure and Applied Chemistry", []],
    ["Journal of Macromolecular Science, Part C,Polymer Reviews", []],
    ["Journal of Materials Chemistry", []],
    ["Journal of Materials Research", []],
    ["Journal of Mathematical Chemistry", []],
    ["Journal of Molecular Structure", []],
    ["Journal of Molecular Structure: THEOCHEM", []],
    ["Journal of Medicinal Chemistry", []],
    ["Journal of Natural Products home)", []],
    ["Journal of Organic Chemistry", []],
    ["Journal of Organometallic Chemistry", []],
    ["Journal of Physical Chemistry A", []],
    ["Journal of Physical Chemistry B", []],
    ["Journal of Physical Chemistry C", []],
    ["Journal of Polymer Science Part A: Polymer Chemistry", []],
    ["Journal of Polymer Science Part B: Polymer Physics", []],
    ["Journal of Radioanalytical and Nuclear Chemistry", []],
    ["Journal of the Royal Institute of Chemistry", []],
    ["Lab on a Chip", []],
    ["Langmuir", []],
    ["Liebigs Annalen der Chemie", []],
    ["Macromolecules", []],
    ["Magnetic Resonance in Chemistry", []],
    ["Medicinal Research Reviews", []],
    ["Mendeleev Communications", []],
    ["Methods in Organic Synthesis", []],
    ["Molbank", []],
    ["Molecular BioSystems", []],
    ["Molecular Physics", []],
    ["Molecules", []],
    ["Nano Letters", []],
    ["Natural Product Reports", []],
    ["Nature Chemical Biology", []],
    ["Nature Materials", []],
    ["Nature Protocols", []],
    ["New Journal of Chemistry", []],
    ["Organic and Biomolecular Chemistry", []],
    ["Organic Letters", []],
    ["Organometallics", []],
    ["Outlooks on Pest Managemment journal home)", []],
    ["Perkin Transactions", []],
    ["Pesticide Outlook", []],
    ["Photochemical and Photobiological Sciences", []],
    ["Photochemistry and Photobiology", []],
    ["PhysChemComm", []],
    ["Physical Chemistry Chemical Physics", []],
    ["Polyhedron", []],
    ["Polymer", []],
    ["Proceedings of the Chemical Society", []],
    ["Progress in Inorganic Chemistry", []],
    ["Progress in Solid State Chemistry", []],
    ["Radiochimica acta", []],
    ["Radiochemistry", []],
    ["Russian Chemical Bulletin", []],
    ["Russian Chemical Reviews", []],
    ["Scientia Pharmaceutica", []],
    ["Separation and Purification Reviews", []],
    ["Separation and Purification Technology", []],
    ["Separation Science and Technology", []],
    ["Soft Matter", []],
    ["Solvent Extraction and Ion Exchange", []],
    ["Spectrochimica Acta", []],
    ["Spectrochimica Acta Part A: Molecular and Biomolecular Spectroscopy", []],
    ["Spectrochimica Acta Part B: Atomic Spectroscopy", []],
    ["Spectroscopy Letters", []],
    ["Surface Science", []],
    ["Surface Science Letters", []],
    ["Surface Science Reports", []],
    ["Synlett", []],
    ["Synthesis", []],
    ["Sensors and Actuators", []],
    ["Talanta", []],
    ["Tetrahedron", []],
    ["Tetrahedron Asymmetry", []],
    ["Tetrahedron Letters", []],
    ["Theoretical Chemistry Accounts", []],
    ["Zeitschrift für Physikalische Chemie", []]
  ].map{|a| a[-1] = [Topics::CHEMISTRY]+a[-1]; a }))

  # Computer science
  JOURNALS.push(*( [
    ["Journal of the ACM", []],
    ["Communications of the ACM", []],
    ["Computing Reviews", []],
    ["IEEE Transactions on Computers", []],
    ["International Journal of Critical Computer-Based Systems", []],
    ["Journal of Machine Learning Research", [Topics::ML]],
    ["Journal of Functional Programming", [Topics::FP]],
    ["SIAM Journal on Computing[", []],
    ["IEEE Computer", []],
    ["ACM Transactions on Graphics", [Topics::GFX]],
    ["ACM Transactions on Computer-Human Interaction", [Topics::CHI]],
    ["CHI Letters", [Topics::CHI]],
    [/\bLNCS|Lecture Notes in Computer Science\b/, "Lecture Notes in Computer Science", []]
  ].map{|a| a[-1] = [Topics::CS]+a[-1]; a }))

  # Earth and atmospheric sciences
  JOURNALS.push(*( [
    ["Eos", []],
    ["Geophysical Research Letters", []],
    ["Nature Geoscience", []],
    ["Episodes", []],
    ["Geophysics", []],
    ["Journal of Geophysical Research", []],
    ["Reviews of Geophysics", []],
  ].map{|a| a[-1] = [Topics::GEOPHYS]+a[-1]; a }))
  # Earth Science
  JOURNALS.push(*( [
    ["Journal of Earth System Science", []],

    ["American Journal of Science", []],
    ["Canadian Journal of Earth Science", []],
    ["Earth and Planetary Science Letters", []],
    ["Earth in Space", []],
    ["Earth Interactions", []],
    ["Earth-Science Reviews", []],
    ["Global Environmental Change", []],
    ["International Journal of Remote Sensing", []]
  ].map{|a| a[-1] = [Topics::EARTHSCI]+a[-1]; a }))
  # Hydrology
  JOURNALS.push(*( [
    ["Advances in Water Resources", []],
    ["Journal of Hydrology", []],
    ["Water Resources Research", []],
  ].map{|a| a[-1] = [Topics::HYDROLOGY]+a[-1]; a }))
  # Geochemistry and Mineralogy
  JOURNALS.push(*( [
    ["American Mineralogist", []],
    ["Applied Geochemistry", []],
    ["Canadian Mineralogist", []],
    ["Chemical Geology", []],
    ["Clays and Clay Minerals", []],
    ["Geochemical Transactions", []],
    ["Geochimica et Cosmochimica Acta", []],
    ["Geomicrobiology Journal", []],
    ["Mineralogical Magazine", []],
    ["Organic Geochemistry", []],
    ["Physics and Chemistry of Minerals", []],
    ["Reviews in Mineralogy & Geochemistry", []],
  ].map{|a| a[-1] = [Topics::GEOCHEM, Topics::MINERALOGY]+a[-1]; a }))
  # Geology
  JOURNALS.push(*( [
    ["Bulletin of Volcanology", []],
    ["Canadian Mineralogist", []],
    ["Geodinamica Acta", []],
    ["Geofluids", []],
    ["Geological Journal", []],
    ["Geology", []],
    ["Geomorphology", []],
    ["Holocene", []],
    ["International Journal of Speleology", []],
    ["Journal of Geology", []],
    ["Journal of Metamorphic Geology", []],
    ["Journal of Sedimentary Research", []],
    ["Journal of Structural Geology", []],
    ["Journal of the Geological Society", []],
    ["Journal of Volcanology and Geothermal Research", []],
    ["Lithos", []],
    ["Northeastern Geology", []],
    ["Oil and Gas Journal", []],
    ["Palaios", []],
    ["Sedimentary Geology", []],
    ["Sedimentary Petrolology", []],
    ["Sedimentology", []]
  ].map{|a| a[-1] = [Topics::GEOLOGY]+a[-1]; a }))
  # Oceanography
  JOURNALS.push(*( [
    ["Atmosphere-Ocean", []],
    ["Deep-Sea Research Part I", []],
    ["Deep-Sea Research Part II", []],
    ["Journal of Geophysical Research- Atmosphere", []],
    ["Journal of Geophysical Research- Planets", []],
    ["Journal of Geophysical Research- Solids", []],
    ["Journal of Physical Oceanography", []],
    ["Limnology & Oceanography", []],
    ["Marine Chemistry", []],
    ["Marine Geology", []],
    ["Netherlands Journal of Sea Research", []],
    ["Oceanography & Marine Biology", []],
    ["Paleoceanography", []],
    ["Progress in Oceanography", []],
    ["Reviews in Aquatic Sciences", []]
  ].map{|a| a[-1] = [Topics::OCEANOGRAPHY]+a[-1]; a }))
  # Glaciology
  JOURNALS.push(*( [
    ["Journal of Glaciology", []],
    ["Annals of Glaciology", []]
  ].map{|a| a[-1] = [Topics::GLACIOLOGY]+a[-1]; a }))
  # Atmospheric Science
  JOURNALS.push(*( [
    ["Aerobiologica", []],
    ["Agricultural and Forest Meteorology", []],
    ["Atmosphere-Ocean", []],
    ["Atmospheric and Oceanic Physics", []],
    ["Atmospheric Chemistry and Physics", []],
    ["Atmospheric Environment", []],
    ["Atmospheric Research", []],
    ["Atmospheric Science Letters", []],
    ["Boundary-Layer Meteorology", []],
    ["Bulletin of the American Meteorological Society", []],
    ["Climate Dynamics", []],
    ["Climatic Change", []],
    ["Contributions to Atmospheric Physics", []],
    ["Electronic Journal of Operational Meteorology", []],
    ["Electronic Journal of Severe Storms Meteorology", []],
    ["International Journal of Biometeorology", []],
    ["International Journal of Climatology", []],
    ["Journal of Applied Meteorology and Climatology", []],
    ["Journal of Atmospheric and Oceanic Technology", []],
    ["Journal of Atmospheric and Solar-terrestrial Physics", []],
    ["Journal of Atmospheric Chemistry", []],
    ["Journal of Climate and Applied Meteorology", []],
    ["Journal of Climate", []],
    ["Journal of Hydrometeorology", []],
    ["Journal of the Atmospheric Sciences", []],
    ["Journal of the Meteorological Society of Japan", []],
    ["Journal of Meteorology", []],
    ["Journal of Paleoclimatology", []],
    ["Meteorological Applications", []],
    ["Meteorological Monographs", []],
    ["Meteorology and Atmospheric Physics", []],
    ["Monthly Weather Review", []],
    ["Progress in Biometeorology", []],
    ["Quarterly Journal of the Royal Meteorological Society", []],
    ["National Weather Digest", []],
    ["Tellus. Series A: Dynamic Meteorology and Oceanography", []],
    ["Tellus. Series B: Chemical and Physical Meteorology", []],
    ["Weather and Forecasting", []],
    [/\bWeather\s+\(?Royal Met(\.|eorological) Soc(\.|iety)/, "Weather", []]
  ].map{|a| a[-1] = [Topics::ATMOSPHERE]+a[-1]; a }))

  # Engineering
  JOURNALS.push(*( [
    ["Advances in Production Engineering & Management", []],
    ["Annual Review of Biomedical Engineering", [Topics::BIOMED]],
    ["Fluid Phase Equilibria", []],
    ["Industrial & Engineering Chemistry Research", [Topics::CHEMENG]],
    ["Journal of Environmental Engineering", [Topics::ENVENG]],
    ["Journal of Hydrologic Engineering", [Topics::HYDENG]],
    ["Journal of the IEST", []],
    ["NASA Tech Briefs", []],
    ["Post Office Electrical Engineers' Journal", [Topics::ELEENG]]
  ].map{|a| a[-1] = [Topics::ENG]+a[-1]; a }))

  # Materials science
  JOURNALS.push(*( [
    ["Advanced Materials", []],
    ["Advanced Functional Materials", []],
    ["JOM", []],
    ["Journal of Electronic Materials", []],
    ["Materials Today", []],
    ["Metallurgical and Materials Transactions", []],
    ["Nature Materials", []]
  ].map{|a| a[-1] = [Topics::MATERIALS]+a[-1]; a }))

  # Mathematics
  JOURNALS.push(*( [
    ["Acta Mathematica Academiae Paedagogicae Nyíregyháziensis", []],
    ["Acta Mathematica Universitatis Comenianae", []],
    ["Acta Mathematica", []],
    ["Acta Numerica", []],
    ["Acta Scientiarum Mathematicarum", []],
    ["Advances in Applied Mathematics", []],
    ["Advances in Difference Equations", []],
    ["Advances in Geometry", []],
    ["Advances in Mathematics", []],
    ["Advances in Theoretical and Mathematical Physics", []],
    ["Algebra & Number Theory", []],
    ["Algebraic & Geometric Topology", []],
    ["American Journal of Mathematics", []],
    ["American Mathematical Monthly", []],
    ["Analysis & PDE", []],
    ["Annales Academiae Scientiarum Fennicae. Mathematica", []],
    ["Annales Henri Poincaré", []],
    ["Annales Scientifiques de l'École Normale Supérieure", []],
    ["Annali della Scuola Normale Superiore di Pisa - Classe di Scienze", []],
    ["Annals of Mathematics", []],
    ["Annals of Mathematical Statistics", []],
    ["Applied Mathematics E - Notes", []],
    ["Applied Sciences", []],
    ["Archive for Rational Mechanics and Analysis", []],
    ["Archivum Mathematicum", []],
    ["Asian journal of mathematics", []],
    ["Atti dell'Accademia Peloritana dei Pericolanti - Classe di Scienze Fisiche, Matematiche e Naturali", []],
    ["Balkan Journal of Geometry and Its Applications", []],
    ["Banach Journal of Mathematical Analysis", []],
    ["Boletin Asociacio Matematica Vanezolana", []],
    ["Boundary Value Problems", []],
    ["Brazilian Journal of Probability and Statistics", []],
    ["Bulletin of TICMI", []],
    ["Bulletin of the American Mathematical Society", []],
    ["Bulletin of the London Mathematical Society", []],
    ["Bulletin, Classes des Sciences Mathematiques et Naturelles, Sciences", []],
    ["Bulletin of Statistics & Economics", []],
    ["Canadian Mathematical Bulletin", []],
    ["Canadian Journal of Mathematics", []],
    ["Combinatorics, Probability and Computing", []],
    ["Commentarii Mathematici Helvetici", []],
    ["Communications in Algebra", []],
    ["Communications in Mathematical Analysis", []],
    ["Communications in Mathematical Physics", []],
    ["Communications on Pure and Applied Mathematics", []],
    ["Compositio Mathematica", []],
    ["Computational and Applied Mathematics", []],
    ["Differential Equations and Control Processes", []],
    ["Differential Equations and Nonlinear Mechanics", []],
    ["Differential Geometry - Dynamical systems", []],
    ["Discrete Dynamics in Nature and Society", []],
    ["Discrete Mathematics & Theoretical Computer Science", []],
    ["Divulgaciones Matematicas", []],
    ["Documenta Mathematica", []],
    ["Duke Mathematical Journal", []],
    ["Electronic Journal of Combinatorics", []],
    ["Electronic Journal of Linear Algebra", []],
    ["Electronic Journal of Qualitative Theory of Differential Equations", []],
    ["Electronic Research Announcements of the American Mathematical Society", []],
    ["Electronic Transactions on Numerical Analysis", []],
    ["Ergodic Theory and Dynamical Systems", []],
    ["European Journal of Applied Mathematics", []],
    ["Far East Journal of Mathematical Sciences", []],
    ["Fibonacci Quarterly", []],
    ["Filomat", []],
    ["Fixed Point Theory and Applications", []],
    ["Formalized Mathematics", []],
    ["Forum Geometricorum: A Journal on Classical Euclidean Geometry", []],
    ["Fundamenta Mathematicae", []],
    ["Geometry & Topology", []],
    ["Glasgow Mathematical Journal", []],
    ["Glasnik Matematicki", []],
    ["Hiroshima Mathematical Journal", []],
    ["Homology, Homotopy and Applications", []],
    ["Indiana University Mathematics Journal", []],
    ["Integers: Electronic Journal of Combinatorial Number Theory", []],
    ["Integral Equations and Operator Theory", []],
    ["InterJournal", []],
    ["Interdisciplinary Information Sciences", []],
    ["International Journal for Mathematics Teaching and Learning", []],
    ["International Journal of Applied Mathematics and Computer Science", []],
    ["International Journal of Applied Mathematics & Statistics", []],
    ["International Journal of Intelligent Technologies and Applied Statistics", []],
    ["International Journal of Mathematics", []],
    ["International Journal of Mathematics and Statistics", []],
    ["International journal of simulation. Systems, science and technology", []],
    ["International Journal of Tomography and Statistics", []],
    ["Inventiones Mathematicae", []],
    ["Involve, a Journal of Mathematics", []],
    ["Journal de Mathématiques Pures et Appliquées", []],
    ["Journal für die reine und angewandte Mathematik - the oldest surviving mathematical periodical", []],
    ["Journal of Algebra", []],
    ["Journal of Applied Mathematics", []],
    ["Journal of the Australian Mathematical Society", []],
    ["Journal of Commutative Algebra", []],
    ["Journal of Differential Geometry", []],
    ["Journal of Fluid Mechanics", []],
    ["Journal of Functional Analysis", []],
    ["Journal of Geometry", []],
    ["Journal of Graph Algorithms and Applications", []],
    ["Journal of Inequalities in Pure and Applied Mathematics", []],
    ["Journal of Integer Sequences", []],
    ["Journal of Mathematical Physics", []],
    ["Journal of Mathematical Sciences", []],
    ["Journal of Mathematics and Statistics", []],
    ["Journal of Nonlinear Mathematical Physics", []],
    ["Journal of Number Theory", []],
    ["Journal of Online Mathematics and its Applications", []],
    ["Journal of Operator Theory", []],
    ["Journal of Pure and Applied Algebra", []],
    ["Journal of the American Mathematical Society", []],
    ["Journal of the London Mathematical Society", []],
    ["Journal of the Institute of Mathematics of Jussieu", []],
    ["Kyungpook Mathematical Journal", []],
    ["Kyushu Journal of Mathematics", []],
    ["Lobachevskii Journal of Mathematics", []],
    ["Manuscripta Mathematica", []],
    ["Matematicki Vesnik", []],
    ["Mathematica Scandinavica", []],
    ["Mathematical Inequalities & Applications", []],
    ["Mathematical Journal of Okayama University", []],
    ["Mathematical Physics Electronic Journal", []],
    ["Mathematical Problems in Engineering", []],
    ["Mathematical Proceedings of the Cambridge Philosophical Society", []],
    ["Mathematical Structures in Computer Science", []],
    ["Mathematics of Computation", []],
    ["Mathematische Annalen", []],
    ["Mathematische Nachrichten", []],
    ["Mathematische Zeitschrift", []],
    ["Missouri Journal of Mathematical Sciences", []],
    ["Multiscale Modeling and Simulation", []],
    ["Nagoya Mathematical Journal", []],
    ["Nexus Network Journal: architecture and mathematics", []],
    ["Notices of the American Mathematical Society", []],
    ["Pacific Journal of Mathematics", []],
    ["Proceedings of Symposia in Pure Mathematics", []],
    ["Proceedings of the American Mathematical Society", []],
    ["Proceedings of the Edinburgh Mathematical Society", []],
    ["Proceedings of the Indian Academy of Sciences: Mathematical Sciences", []],
    ["Proceedings of the Japan Academy. Series A, Mathematical Sciences", []],
    ["Proceedings of the Royal Society of Edinburgh: Section A Mathematics", []],
    ["Proyecciones- Revista de matemetica", []],
    ["Publications Mathematiques de l'IHES", []],
    ["Publications de l'Institut Mathematique", []],
    ["Quaestiones Mathematicae", []],
    ["Rendiconti del Seminario Matematico della Università e Politecnico di Torino", []],
    ["Rendiconti del Seminario Matematico della Università di Padova", []],
    ["Ricerche di Matematica", []],
    ["SIAM Journal on Applied Dynamical Systems", []],
    ["SIAM Journal on Applied Mathematics", []],
    ["SIAM Journal on Computing", []],
    ["SIAM Journal on Control and Optimization", []],
    ["SIAM Journal on Discrete Mathematics", []],
    ["SIAM Journal on Mathematical Analysis", []],
    ["SIAM Journal on Matrix Analysis and Applications", []],
    ["SIAM Journal on Numerical Analysis", []],
    ["SIAM Journal on Optimization", []],
    ["SIAM Journal on Scientific Computing", []],
    ["SIAM Review", []],
    ["Seminaire Lotharingien de Combinatoire", []],
    ["Siberian Electronic Mathematical Reports", []],
    ["Siberian Mathematical Journal", []],
    ["Solstice : An Electronic Journal of Geography and Mathematics", []],
    ["Southwest Journal of Pure and Applied Mathematics", []],
    ["Studia Mathematica", []],
    ["Symmetry, Integrability and Geometry: Methods and Applications", []],
    ["Taiwanese Journal of Mathematics, TJM", []],
    ["The Electronic Journal of Combinatorics", []],
    ["The Mathematics Educator", []],
    ["The Montana Mathematics Enthusiast", []],
    ["The New York Journal of Mathematics", []],
    ["Theory and Applications of Categories", []],
    ["Theory of Probability and Its Applications", []],
    ["Topology", []],
    ["Topology and its Applications", []],
    ["Transactions of the American Mathematical Society", []],
    ["Turkish Journal of Mathematics", []]
  ].map{|a| a[-1] = [Topics::MATH]+a[-1]; a }))

  # Medicine
  JOURNALS.push(*( [
    ["AACN Clinical Issues", []],
    ["Academic Emergency Medicine", []],
    ["Academic Medicine", []],
    ["Academic Physician & Scientist", []],
    ["ACIMED", []],
    ["ACP Journal", []],
    ["ACSM's Health & Fitness Journal", []],
    ["Acta Anaesthesiologica Scandinavica", []],
    ["Acta Cientifica Estudiantil", []],
    ["Acta Neurologica Belgica", []],
    ["Acta Neurologica Scandinavica", []],
    ["Acta Otorhinolaryngologica Italica", []],
    ["Acta Paediatrics", []],
    ["Acta Psychiatrica Scandinavica", []],
    ["Acta Radiologica", []],
    ["Addictive Behavior", []],
    ["Addictive Disorders and Their Treatment", []],
    ["Advances in Anatomic Pathology", []],
    ["Advances in Mind-Body Medicine", []],
    ["Advances in Neurology", []],
    ["Advances in Renal Replacement Therapy", []],
    ["Advances in Skin & Wound Care", []],
    ["AIDS", []],
    ["Alzheimer's Care Today", []],
    ["Alzheimer's Disease and Associated Disorders", []],
    ["American Family Physician", []],
    ["American Journal of Clinical Oncology", []],
    ["American Journal of Epidemiology", []],
    ["American Journal of Gastroenterology", []],
    ["American Journal of Medical Genetics", []],
    ["The American Journal of the Medical Sciences", []],
    ["American Journal of Obstetrics and Gynecology", []],
    ["American Journal of Physical Medicine & Rehabilitation", []],
    ["American Journal of Public Health", []],
    ["American Journal of Sports Medicine", []],
    ["American Journal of Surgery", []],
    ["American Journal of Therapeutic Medicine", []],
    ["The American Journal of Surgical Pathology", []],
    ["Anaesthesia", []],
    ["Anesthesia & Analgesia", []],
    ["Anesthesiology", []],
    ["Annals of Emergency Medicine", []],
    ["Annals of Family Medicine", []],
    ["Annals of Human Biology", []],
    ["Annals of Human Genetics", []],
    ["Annals of Internal Medicine", []],
    ["Annals of Plastic Surgery", []],
    ["Annals of Surgery", []],
    ["Annals of Surgery", []],
    ["Annual Review of Medicine", []],
    ["Anti-Cancer Drugs", []],
    ["Applied Immunohistochemistry & Molecular Morphology", []],
    ["Archives of Dermatology", []],
    ["Archives of Disease in Childhood", []],
    ["Archives of Facial Plastic Surgery", []],
    ["Archives of General Psychiatry", []],
    ["Archives of Internal Medicine", []],
    ["Archives of Neurology", []],
    ["Archives of Ophthalmology", []],
    ["Archives of Otolaryngology - Head & Neck Surgery", []],
    ["Archives of Pediatric & Adolescent Medicine", []],
    ["Archives of Surgery", []],
    ["Archives of Medicine", []],
    ["Archives, The International Journal of Medicine", []],
    ["Arteriosclerosis, Thrombosis, and Vascular Biology", []],
    ["ASAIO Journal", []],
    ["Asian Journal of Oral and Maxillofacial Surgery", []],
    ["Behavioural Pharmacology", []],
    ["Biology of the Neonate", []],
    ["BioMed Central", []],
    ["Biometrika", []],
    ["Biopharmaceutics & Drug Disposition", []],
    ["Blood", []],
    ["Blood Coagulation and Fibrinolysis", []],
    ["Blood Pressure Monitoring", []],
    ["Brain", []],
    ["Brain & Development", []],
    ["Brazilian Journal of Medical and Biological Research", []],
    ["British Journal of Anaesthesia", []],
    ["British Journal of Cancer'", []],
    ["BJHCM: British Journal of Healthcare Management", []],
    ["British Journal of Hospital Medicine", []],
    ["British Journal of Industrial Medicine", []],
    ["British Journal of Medical Practitioners", []],
    ["British Journal of Obstetrics and Gynecology", []],
    ["British Journal of Sexual Medicine", []],
    ["British Journal of Urology", []],
    ["British Medical Journal", []],
    ["Bulletin of the World Health Organization", []],
    ["CA - A Cancer Journal for Clinicians", []],
    ["Calicut Medical Journal", []],
    ["Canadian Journal of Emergency Medicine", []],
    ["Canadian Medical Association Journal", []],
    ["Cardiology in Review", []],
    ["Circulation", []],
    ["Circulation: Arrhythmia and Electrophysiology", []],
    ["Circulation: Cardiovascular Imaging", []],
    ["Circulation Research", []],
    ["Circulation: Heart Failure", []],
    ["Child Development", []],
    ["Clinical Dysmorphology", []],
    ["Clinical Journal of Sports Medicine", []],
    ["Clinical Microbiology Review", []],
    ["Clinical Neuropharmacology", []],
    ["Clinical Nuclear Medicine", []],
    ["Clinical Obstetrics and Gynecology", []],
    ["Clinical Pulmonary Medicine", []],
    ["Clinical Science", []],
    ["Clinical Obstetrics and Gynecology", []],
    ["Cognitive and Behavioral Neurology", []],
    ["Contemporary Surgery", []],
    ["CONTINUUM", []],
    ["Contraception", []],
    ["Cornea", []],
    ["Coronary Artery Disease", []],
    ["Critical Care Medicine", []],
    ["Critical Pathways in Cardiology", []],
    ["Current Opinion in Allergy and Clinical Immunology", []],
    ["Current Opinion in Anaesthesiology", []],
    ["Current Opinion in Cardiology", []],
    ["Current Opinion in Clinical Nutrition and Metabolic Care", []],
    ["Current Opinion in Critical Care", []],
    ["Current Opinion in Endocrinology, Diabetes and Obesity", []],
    ["Current Opinion in Gastroenterology", []],
    ["Current Opinion in HIV and AIDS", []],
    ["Current Opinion in Hematology", []],
    ["Current Opinion in Infectious Diseases", []],
    ["Current Opinion in Internal Medicine", []],
    ["Current Opinion in Lipidology", []],
    ["Current Opinion in Nephrology and Hypertension", []],
    ["Current Opinion in Neurology", []],
    ["Current Opinion in Obstetrics and Gynecology", []],
    ["Current Opinion in Oncology", []],
    ["Current Opinion in Ophthalmology", []],
    ["Current Opinion in Organ Transplantation", []],
    ["Current Opinion in Otolaryngology & Head and Neck Surgery", []],
    ["Current Opinion in Pediatrics", []],
    ["Current Opinion in Psychiatry", []],
    ["Current Opinion in Pulmonary Medicine", []],
    ["Current Opinion in Rheumatology", []],
    ["Current Opinion in Supportive and Palliative Care", []],
    ["Current Opinion in Urology", []],
    ["Current Orthopaedic Practice", []],
    ["Current Sports Medicine Reports", []],
    ["British Journal of Dermatology", []],
    ["Deutsche Medizinische Wochenschrift", []],
    ["Diabetes/Metabolism: Research and Reviews", []],
    ["Diagnostic Molecular Pathology", []],
    ["Disaster Medicine and Public Health Preparedness", []],
    ["Drug and Alcohol Dependence", []],
    ["Dutch Journal of Medicine", []],
    ["ecancermedicalscience", []],
    ["Ear and Hearing", []],
    ["Emergency Medicine Journal", []],
    ["Emergency Medicine News", []],
    ["Endocrinology", []],
    ["ENToday", []],
    ["Epidemiology", []],
    ["Epilepsy Currents", []],
    ["European Journal of Cancer Prevention", []],
    ["European Journal of Cardiovascular Prevention & Rehabilitation", []],
    ["European Journal of Emergency Medicine", []],
    ["European Journal of Endocrinology", []],
    ["European Journal of Gastroenterology and Hepatology", []],
    ["European Journal of Pediatrics", []],
    ["Evidence-Based Gastroenterology", []],
    ["Evidence-Based Ophthalmology", []],
    ["Exercise and Sport Sciences Reviews", []],
    ["Experimental Gerontology", []],
    ["Eye and Contact Lens: Science and Clinical Practice", []],
    ["ePlasty, Open Access Journal of Plastic Surgery", []],
    ["Family & Community Health", []],
    ["Family Practice Management", []],
    ["Fertility and Sterility", []],
    ["Focus on Alternative and Complementary Therapies", []],
    ["From Theory to More Theory: Journal of Medical Sociology", []],
    ["Gastroenterology", []],
    ["Genetics in Medicine", []],
    ["Growth, Genetics, and Hormones", []],
    ["Gynecological Surgery", []],
    ["Harefuah", []],
    ["Health Care Management Review", []],
    ["Health Data Matrix", []],
    ["Health Physics", []],
    ["Heart", []],
    ["Heart Insight", []],
    ["Highlights of Ophthalmology", []],
    ["Hormone Research", []],
    ["Hospital Pharmacy", []],
    ["Human Psychopharmacology", []],
    ["Human Reproduction", []],
    ["Hypertension", []],
    ["Implant Dentistry", []],
    ["Indian Journal of Medical Sciences", []],
    ["Infants and Young Children", []],
    ["Infectious Diseases in Clinical Practice®", []],
    ["Innovations: Technology and Techniques in Cardiothoracic and Vascular Surgery", []],
    ["International Anesthesiology Clinics", []],
    ["International Clinical Psychopharmacology", []],
    ["International Journal of Biological Sciences", []],
    ["International Journal of Biometeorology", []],
    ["International Journal of Geriatric Psychiatry", []],
    ["International Journal of Gynecological Pathology", []],
    ["International Journal of Health Science", []],
    ["International Ophthalmology Association In The Web Journal", []],
    ["International Journal of Gynaecology and Obstetrics", []],
    ["International Journal of Medical Sciences", []],
    ["International Journal of Psychoanalysis", []],
    ["International Journal of Rehabilitation Research", []],
    ["International Journal of Medicine, The", []],
    ["International Ophthalmology Clinics", []],
    ["Internet Journal of Medical Update", []],
    ["Intervention", []],
    ["Investigative Ophthalmology & Visual Science", []],
    ["Investigative Radiology", []],
    ["Israel Medical Association Journal", []],
    ["Israel Journal of Psychiatry and Related Sciences", []],
    ["Indian Journal of Medical Microbiology", []],
    ["Insuficiencia Cardiaca", []],
    ["JAMA & Archives", []],
    ["JAMA & Archives Continuing Medical Education", []],
    ["JAMA & Archives For The Media", []],
    ["Journal of Acquired Immune Deficiency Syndromes", []],
    ["Journal of Addiction Medicine", []],
    ["Journal of American Physicians and Surgeons", []],
    ["The Journal of Applied Research in Clinical and Experimental Therapeutics", []],
    ["Journal of Bone & Joint Surgery", []],
    ["Journal of Bronchology", []],
    ["Journal of Burn Care & Research", []],
    ["Journal of Cardiopulmonary Rehabilitation and Prevention", []],
    ["Journal of Cardiovascular Medicine", []],
    ["Journal of Cardiovascular Pharmacology", []],
    ["Journal of Clinical Endocrinology & Metabolism", []],
    ["Journal of Clinical Engineering", []],
    ["Journal of Clinical Epidemiology", []],
    ["Journal of Clinical Gastroenterology", []],
    ["Journal of Clinical Investigation", []],
    ["Journal of Clinical Oncology", []],
    ["Journal of Clinical Neuromuscular Disease", []],
    ["Journal of Clinical Neurophysiology", []],
    ["Journal of Clinical Neurophysiology", []],
    ["Journal of Clinical Psychopharmacology", []],
    ["Journal of Clinical Sleep Medicine", []],
    ["Journal of Computer Assisted Tomography", []],
    ["Journal of Computer Assisted Tomography", []],
    ["Journal of Developmental & Behavioral Pediatrics", []],
    ["Journal of Epidemiology and Community Health", []],
    ["Journal of Experimental Medicine", []],
    ["Journals of Gerontology Series A: Biological Sciences and Medical Sciences", []],
    ["Journal of Glaucoma", []],
    ["Journal of Hypertension", []],
    ["Journal of Immunology", []],
    ["Journal of Immunotherapy", []],
    ["Journal of Infection in Developing Countries", []],
    ["Journal of Investigative Dermatology", []],
    ["Journal of Investigative Medicine", []],
    ["Journal of Lower Genital Tract Disease", []],
    ["Journal of Medical Biography", []],
    ["Journal of Medical Case Reports", []],
    ["Journal of Medical Genetics", []],
    ["Journal of Medical Practice Management", []],
    ["Journal of Medical Sciences Research", []],
    ["Journal of Minimally Invasive Gynecology", []],
    ["Journal of Neuro-Ophthalmology", []],
    ["Journal of Neurologic Physical Therapy", []],
    ["Journal of Neuropathology & Experimental Neurology", []],
    ["Journal of Neurosurgical Anesthesiology", []],
    ["Journal of Occupational and Environmental Medicine", []],
    ["Journal of Oncology Practice", []],
    ["Journal of Orthopaedic Trauma", []],
    ["Journal of Patient Safety", []],
    ["Journal of Pediatric Gastroenterology and Nutrition", []],
    ["Journal of Pediatric Hematology/Oncology", []],
    ["Journal of Pediatric Orthopaedics", []],
    ["Journal of Pediatric Orthopaedics B", []],
    ["Journal of Pelvic Medicine & Surgery", []],
    ["Journal of Pineal Research", []],
    ["Journal of Postgraduate Medicine", []],
    ["Journal of Prosthetics and Orthotics", []],
    ["Journal of Psychiatric Practice", []],
    ["Journal of Psychiatric Practice", []],
    ["Journal of Public Health Management and Practice", []],
    ["Journal of Reproductive Immunology", []],
    ["Journal of Reproductive Medicine", []],
    ["Journal of Spinal Disorders & Techniques", []],
    ["Journal of Studies on Alcohol", []],
    ["Journal of Thoracic Imaging", []],
    ["Journal of Thoracic Oncology", []],
    ["Journal of the American Academy of Child & Adolescent Psychiatry", []],
    ["Journal of the American Geriatrics Society", []],
    ["Journal of the American Medical Association", []],
    ["Journal of the American Osteopathic Association", []],
    ["Journal of the National Medical Association", []],
    ["The Journal of the Trauma", []],
    ["Journal of the Royal Society of Medicine", []],
    ["Journal of Burns and Wounds", []],
    ["The Lancet", []],
    ["The Laryngoscope", []],
    ["Läkartidningen", []],
    ["Malta Medical Journal", []],
    ["McGill Journal of Medicine", []],
    ["Medical Journal Armed Forces India", []],
    ["The Medical Journal of Australia", []],
    ["The Medical Letter on Drugs and Therapeutics", []],
    ["Medical Care", []],
    ["Medicine", []],
    ["Medicine & Science in Sports & Exercise", []],
    ["Medicine, Conflict and Survival", []],
    ["Melanoma Research", []],
    ["Menapause", []],
    ["Molecular Medicine", []],
    ["Mount Sinai Journal of Medicine", []],
    ["National Medical Journal of India", []],
    ["Nature Clinical Practice Cardiovascular Medicine", []],
    ["Nature Clinical Practice Endocrinology and Metabolism", []],
    ["Nature Clinical Practice Gastroenterology and Hepatology", []],
    ["Nature Clinical Practice Nephrology", []],
    ["Nature Clinical Practice Neurology", []],
    ["Nature Clinical Practice Oncology", []],
    ["Nature Clinical Practice Rheumatology", []],
    ["Nature Clinical Practice Urology", []],
    ["Nature Medicine", []],
    ["Nature Neuroscience", []],
    ["Nature Reviews Cancer", []],
    ["Nature Reviews Immunology", []],
    ["Nature Reviews Microbiology", []],
    ["Nederlands Tijdschrift voor Geneeskunde", []],
    ["Nephrology Times", []],
    ["Neuroanatomy is an annual journal of clinical neuroanatomy.", []],
    ["Neurology", []],
    ["Neurology Now", []],
    ["Neurology India", []],
    ["NeuroReport", []],
    ["Neurosurgery", []],
    ["Neurosurgery Quarterly", []],
    ["New England Journal of Medicine", []],
    ["New Zealand Medical Journal", []],
    ["New Zealand Medical Student Journal", []],
    ["Nuclear Medicine Communications", []],
    ["Nutrition Today", []],
    ["Obstetrical and Gynecological Survey", []],
    ["Obstetrics and Gynecology", []],
    ["Obstetrics and Gynecology Clinics of North America", []],
    ["Paediatrics", []],
    ["Pediatric Emergency Care", []],
    ["Pediatric Nursing", []],
    ["Pediatric Research", []],
    ["Pediatrics in Review", []],
    ["Pharmacoepidemiology and Drug Safety", []],
    ["Plastic & Reconstructive Surgery", []],
    ["PLoS Medicine", []],
    ["Le Practicien en Anesthésie Réanimation", []],
    ["Prenatal Diagnosis", []],
    ["Psycho-Oncology", []],
    ["Public Health", []],
    ["QJM: An International Journal of Medicine", []],
    ["Radiology Case Reports", []],
    ["Rejuvenation Research", []],
    ["Retina", []],
    ["Reviews in Medical Virology", []],
    ["Revista de la Sociedad Medico-Quirurgica del Hospital de Emergencia Perez de Leon", []],
    ["Scientia Pharmaceutica", []],
    ["Sexually Transmitted Diseases", []],
    ["Sexually Transmitted Infections", []],
    ["South African Family Practice Journal", []],
    ["Solapur Medical Journal", []],
    ["Spine", []],
    ["Sports Medicine", []],
    ["Statistical Methods in Medical Research", []],
    ["Statistics in Medicine", []],
    ["Stroke", []],
    ["Surgical Endocscopy", []],
    ["Techniques in Shoulder and Elbow Surgery", []],
    ["The International Journal of Medical Robotics and Computer Assisted Surgery", []],
    ["The International Journal of Medicine", []],
    ["The Journal of Gene Medicine", []],
    ["The Medical Journal of Australia", []],
    ["The Medical Letter on Drugs and Therapeutics", []],
    ["The New Iraqi Journal of Medicine", []],
    ["Tissue Engineering and Regenerative Medicine", []],
    ["Trends in Molecular Medicine", []],
    ["Trillium Report", []]
  ].map{|a| a[-1] = [Topics::MEDICINE]+a[-1]; a }))
  # Allergy
  JOURNALS.push(*( [
    ["Journal of Allergy Clinical Immunology", []],
    ["Allergy", []],
    ["Clinical & Experimental Allergy", []],
    ["International Archives of Allergy and Immunology", []],
    ["Pediatric Allergy and Immunology", []],
    ["Annual of Allergy and Asthma Immunology", []],
    ["Clinical Review of Allergy Immunology", []],
    ["Contact Dermatitis", []],
    ["Journal of Asthma", []],
    ["Allergy Asthma Proceedings", []],
    ["Annals of Allergy", []],
    ["European Journal of Allergy & Clinical Immunology", []]
  ].map{|a| a[-1] = [Topics::MEDICINE, Topics::ALLERGY]+a[-1]; a }))
  # Anesthesiology
  JOURNALS.push(*( [
    ["Pain", []],
    ["Anesthesiology", []],
    ["Clinical Journal of Pain", []],
    ["British Journal of Anaesthesia", []],
    ["Anesthesia & Analgesia", []],
    ["Anaesthesia", []],
    ["European Journal of Pain", []],
    ["Regional Anesthesia and Pain Medicine", []],
    ["Acta Anaesthesiologica Scandinavica", []],
    ["Canadian Journal of Anaesthesia", []],
    ["International Anesthesiology Clinics", []],
    ["Journal of Clinical Monitoring", []],
    ["Le Practicien en Anesthésie Réanimation", []]
  ].map{|a| a[-1] = [Topics::MEDICINE, Topics::ANESTHESIOLOGY]+a[-1]; a }))
  # Pharmaceutical Sciences
  JOURNALS.push(*( [
    ["Biopharmaceutics & Drug Disposition", []],
    ["Cell Biochemistry and Function", []],
    ["European journal of Pharmaceutical sciences", []],
    ["Health Economics", []],
    ["Human Psychopharmacology: Clinical & Experimental", []],
    ["International Journal of Geriatric Psychiatry", []],
    ["Indian Journal of Pharmaceutical Sciences", []],
    ["International Journal of Medical Sciences", []],
    ["International Journal of Pharmaceutics", []],
    ["Journal of Pharmaceutical sciences", []],
    ["Pharmacoepidemiology and Drug Safety", []],
    ["Phytotherapy Research", []],
    ["Scientia Pharmaceutica", []],
    ["The Journal of Gene Medicine", []],
    ["The Quality Assurance Journal", []],
    ["Tissue Engineering and Regenerative Medicine", []],
    ["American Journal of Pharmaceutical Education", []],
    ["Biological & Pharmaceutical Bulletin", []],
    ["Brazilian Journal of Pharmaceutical Sciences", []],
    ["Canadian Pharmaceutical Marketing", []],
    ["Chemical & Pharmaceutical Bulletin", []],
    ["European Pharmaceutical Review", []],
    ["Indian Journal of Pharmaceutical Education and Research", []],
    ["Indian Journal of Pharmaceutical Sciences", []],
    ["Iranian Journal of Pharmaceutical Research", []],
    ["Journal of Biomedical & Pharmaceutical Engineering", []],
    ["Journal of Pharmacy and Pharmaceutical Sciences", []],
    ["Pharmaceutical and Medical Packaging News", []],
    ["Pharmaceutical Executive", []],
    ["Pharmaceutical Journal", []],
    ["Pharmaceutical Manufacturing", []],
    ["Pharmaceutical Processing", []],
    ["Pharmaceutical Technology", []],
    ["Pharmaceutical Technology Europe", []],
    ["Pharmaceuticals", []],
    ["South African Pharmaceutical Journal", []],
    ["Tropical Journal of Pharmaceutical Research", []]
  ].map{|a| a[-1] = [Topics::MEDICINE, Topics::PHARSCI]+a[-1]; a }))
  # Psychiatry
  JOURNALS.push(*( [
    ["Archives of General Psychiatry", []],
    ["Molecular Psychiatry", []],
    ["American Journal of Psychiatry", []],
    ["Schizophrenia Bulletin", []],
    ["British Journal of Psychiatry", []],
    ["Biological Psychiatry", []],
    ["Schizophrenia Research", []],
    ["Journal of Clinical Psychiatry", []],
    ["Neuropsychopharmacology", []],
    ["Sleep", []]
  ].map{|a| a[-1] = [Topics::MEDICINE, Topics::PSYCHIATRY]+a[-1]; a }))
  # Toxicology
  JOURNALS.push(*( [
    ["Toxicology", []],
    ["The Journal of Toxicological Sciences", []]
  ].map{|a| a[-1] = [Topics::MEDICINE, Topics::TOXICOLOGY]+a[-1]; a }))

  # Physics (general)
  JOURNALS.push(*( [
    ["Acta Physica Polonica", []],
    ["Advances in Physics", []],
    ["American Journal of Physics", []],
    ["Anales de Física", []],
    ["Annalen der Physik", []],
    ["Annales de Physique", []],
    ["Annals of Physics", []],
    ["Annual Review of Fluid Mechanics", []],
    ["Applied Physics Letters", []],
    ["Doklady Physics", []],
    ["European Physical Journal", []],
    ["Europhysics Letters", []],
    ["Fizika", []],
    ["Helvetica Physica Acta", []],
    ["Journal de Physique", []],
    ["Journal of Physics", []],
    ["Journal of Applied Physics", []],
    ["Nature Physics", []],
    ["Physica Scripta", []],
    ["Physical Review", []],
    ["Physics Reports", []],
    ["Journal of the Physical Society of Japan", []],
    ["Journal of Experimental and Theoretical Physics", []],
    ["Physics Today", []],
    ["Reports on Progress in Physics", []],
    ["Reviews of Modern Physics", []],
    ["Technical Physics", []],
    ["Uspekhi Fizicheskikh Nauk", []]
  ].map{|a| a[-1] = [Topics::PHYSICS]+a[-1]; a }))
  # Acoustics
  JOURNALS.push(*( [
    ["Ultrasound in Obstetrics & Gynecology", []],
    ["Ultrasonic Imaging", []],
    ["Ultrasonic Sonochemistry", []],
    ["IEEE Transactions On Ultrasonics, Ferroelectrics, And Frequency Control", []],
    ["Journal of the Acoustic Society of America", []],
    ["Journal of Ultrasound in Medicine", []],
    ["IEEE Transactions on Audio, Speech & Language Processing", []],
    ["Journal of the Audio Engineering Society", []],
    ["Journal of Clinical Ultrasound", []],
    ["Phonetica", []],
    ["Wave Motion", []],
    ["Technical Acoustics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::ACOUSTICS]+a[-1]; a }))
  # Atomic and molecular physics
  JOURNALS.push(*( [
    ["Physical Review A", []],
    ["European Physical Journal D", []],
    ["Journal of Physics B", []],
    ["Laser Physics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS]+a[-1]; a }))
  # Plasma physics
  JOURNALS.push(*( [
    ["IEEE Transactions on Plasma Science", []],
    ["Journal of Plasma Physics", []],
    ["Nuclear Fusion", []],
    ["Plasma Physics and Controlled Fusion", []],
    ["Physics of Plasmas", []],
    ["Plasma Sources Science and Technology", []],
    ["Plasma Science and Technology", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::PLASMA]+a[-1]; a }))
  # Measurement
  JOURNALS.push(*( [
    ["Measurement Science and Technology", []],
    ["Metrologia", []],
    ["Review of Scientific Instruments", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::MEASUREMENT]+a[-1]; a }))
  # Nuclear physics
  JOURNALS.push(*( [
    ["Physical Review C", []],
    ["Nuclear Physics A", []],
    ["Atomic Data and Nuclear Data Tables", []],
    ["Nuclear Data Sheets", []],
    ["Nuclear Instruments and Methods in Physics Research", []],
    ["European Physical Journal A", []],
    ["Journal of Physics G", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::NUCLEAR]+a[-1]; a }))
  # Optics
  JOURNALS.push(*( [
    ["Advances in Atomic, Molecular, and Optical Physics", []],
    ["Applied Physics B", []],
    ["Applied Optics", []],
    ["Optics Communications", []],
    ["Optics Express", []],
    ["Optics Letters", []],
    ["Journal of Biomedical Optics", []],
    ["Journal of Optics A", []],
    ["Journal of Physics B", []],
    ["Journal of the European Optical Society: Rapid Publications", []],
    ["Journal of the Optical Society of America A", []],
    ["Journal of the Optical Society of America B", []],
    ["Progress in Optics", []],
    ["Nature Photonics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::OPTICS]+a[-1]; a }))
  # Condensed Matter and Materials Science
  JOURNALS.push(*( [
    ["Applied Physics A", []],
    ["European Physical Journal B", []],
    ["International Journal of Modern Physics B", []],
    ["Journal of Physics and Chemistry of Solids", []],
    ["Journal of Physics: Condensed Matter", []],
    ["Journal of Non-crystalline Solids", []],
    ["Journal of Magnetism and Magnetic Materials", []],
    ["Modern Physics Letters B", []],
    ["Nature Materials", []],
    ["Philosophical Magazine", []],
    ["Philosophical Magazine Letters", []],
    ["Physica B", []],
    ["Physica C", []],
    ["Physica E", []],
    ["Physica Status Solidi", []],
    ["Physics of Fluids", []],
    ["Physics of the Solid State", []],
    ["Semiconductors", []],
    ["Solid State Communications", []],
    ["Synthetic Metals", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::MATERIALS]+a[-1]; a }))
  # Low Temperature Physics
  JOURNALS.push(*( [
    ["Journal of Low Temperature Physics", []],
    ["Low Temperature Physics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::LOWTEMP]+a[-1]; a }))
  # Chemical Physics
  JOURNALS.push(*( [
    ["Chemical Physics Letters", []],
    ["Chemical Physics", []],
    ["Journal of Chemical Physics", []],
    ["Physical Chemistry Chemical Physics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::CHEMPHYS]+a[-1]; a }))
  # Soft Matter Physics
  JOURNALS.push(*( [
    ["Granular Matter", []],
    ["Journal of Polymer Science B: Polymer Physics", []],
    ["Soft Matter", []],
    ["European Physical Journal E", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::SOFTMATPHYS]+a[-1]; a }))
  # Medical Physics
  JOURNALS.push(*( [
    ["Medical Physics", []],
    ["Physics in Medicine and Biology", []],
    ["Journal of Applied Clinical Medical Physics", []],
    ["Radiotherapy and Oncology", []],
    ["International Journal of Radiation Oncology Biology Physics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::MEDPHYS]+a[-1]; a }))
  # Biological Physics
  JOURNALS.push(*( [
    ["Biophysical Journal", []],
    ["Biophysics", []],
    ["European Biophysics Journal", []],
    ["Journal of Biological Physics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::BIOPHYS]+a[-1]; a }))
  # Statistical and Nonlinear Physics
  JOURNALS.push(*( [
    ["Physica A", []],
    ["Journal of Statistical Physics", []],
    ["Journal of Statistical Mechanics", []],
    ["Chaos", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::STATPHYS]+a[-1]; a }))
  # Theoretical Physics
  JOURNALS.push(*( [
    ["Advances in Theoretical and Mathematical Physics", []],
    ["Annales de l'Institut Henri Poincaré A", []],
    ["Classical and Quantum Gravity", []],
    ["Communications in Mathematical Physics", []],
    ["Journal of Mathematical Physics", []],
    ["Progress of Theoretical Physics", []],
    ["International Journal of Modern Physics A", []],
    ["Nuclear Physics B", []],
    ["Theoretical and Mathematical Physics", []]
  ].map{|a| a[-1] = [Topics::PHYSICS, Topics::THEOPHYS]+a[-1]; a }))

  # Statistics
  JOURNALS.push(*( [
    ["Journal of Agricultural, Biological, and Environmental Statistics", []],
    ["Journal of the American Statistical Association", []],
    ["The American Statistician", []],
    ["Annals of Applied Probability", []],
    ["Annals of Applied Statistics", []],
    ["The Annals of Probability", []],
    ["The Annals of Statistics", []],
    ["Journal of Applied Econometrics", []],
    ["Bernoulli", []],
    ["Biometrics", []],
    ["Biometrika", []],
    ["Biostatistics", []],
    ["Journal of Biopharmaceutical Statistics", []],
    ["Journal of Business & Economic Statistics", []],
    ["The Canadian Journal of Statistics", []],
    ["Clinical Trials: Journal of the Society for Clinical Trials", []],
    ["Communications in Statistics", []],
    ["Journal of Computational and Graphical Statistics", []],
    ["Journal of Econometrics", []],
    ["Journal of Industrial and Management Optimization", []],
    ["The International Journal of Biostatistics", []],
    ["International Journal of Intelligent Technologies and Applied Statistics", []],
    ["Journal of the Royal Statistical Society", []],
    ["Statistical Applications in Genetics and Molecular Biology", []],
    ["Statistical Science", []],
    ["Statistics in Medicine", []],
    ["Statistics in Biopharmaceutical Research", []],
    ["Journal of Statistical Software", []],
    ["Technology Innovations in Statistics Education", []],
    ["Technometrics", []],
    ["Journal of Time Series Analysis", []]
  ].map{|a| a[-1] = [Topics::STATISTICS]+a[-1]; a }))


  # Science
  JOURNALS.push(*( [
    ["Philosophical Transactions of the Royal Society", []],
    ["Proceedings of the National Academy of Sciences", []],
    ["Proceedings of the Royal Society", []],
    ["Nature", []],
    ["Science", []]
  ].map{|a| a[-1] = [Topics::SCIENCE]+a[-1]; a }))

  PUBLICATIONS = JOURNALS.map{|pattern,name,topics|
    unless topics
      topics = name
      name = pattern
      pattern = /\b#{Regexp.escape(name)}\b/
    end
    [pattern, name, topics]
  }.sort_by{|p,n,g|
    [TitleGuesser::WORDS[n.strip.downcase] ? 1 : 0, -n.length, -g.length]
  }
  # Sort by length, descending. Non-words first.
  # If many have same name, put ones with most topics first.

  SIG_CONFERENCES = [
    ["ACT", [Topics::ALG, Topics::TOC]],
    ["CHI", [Topics::CHI]],
    ["MOD", [Topics::DM]],
    ["GRAPH", [Topics::GFX]],
    ["PLAN", [Topics::PL]]
  ]

  CONFERENCES = SIG_CONFERENCES.map{|s,g|
    [/\bSIG#{s}\b/, "SIG#{s}", [Topics::CS]+g]
  } + [
    [/\bCHI'\d\d\b/, "SIGCHI", [Topics::CS, Topics::CHI]],
    [/\bEuroGraphics[^a-zA-Z]/i, "EuroGraphics", [Topics::CS, Topics::GFX]],
    [/\bICFP[^a-zA-Z]/, "ICFP", [Topics::CS, Topics::FP]],
    [/\bIPTPS[^a-zA-Z]/, "IPTPS"],
    [/\bPEPM[^a-zA-Z]/, "PEPM"],
    [/\bDocEng[^a-zA-Z]/, "DocEng"],
    [/\bUIST[^a-zA-Z]/, "UIST", [Topics::CS, Topics::CHI]],
    [/\bInt\. Symp\. on Smart Graphics\b/i, "Int. Symp. on Smart Graphics", [Topics::CS, Topics::GFX]]
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

