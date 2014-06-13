package Doc;

use utf8;
use Encode;
binmode(STDOUT,":utf8");
use strict;
use locale;
use IO::Handle;
use LWP::Simple;
use XML::Writer;
use IO::File;

# Instructions exécutées au chargement
BEGIN {
	STDOUT->autoflush();
}
END {
	# instructions pour faire le ménage....
}

#**************************************************** Variables

our $SourceUrl="www.ub.uni-koeln.de";			# l’url du doc source
our $defaultTitle="RÉACTIONS; - Sarkozy : &quot; Tout ne peut";				# le titre
our $defaultAuthor="NULL";				# l’auteur
our $defaultDate="02/01/2008";				# la date, au format AAAA-MM-YY (le cas échéant)
our $defaultContent="sarkozy tout ne peut";			# le contenu en texte brut
our $defaultType="journalistique";				# journalistique, etc.
our $defaultGenre="ARTICLE";				# article, etc
our $defaultXip="test.xml";				# le résultat de l’analyse de XIP

#**************************************************** Méthodes

# Constructeur de l'objet Doc
sub new {
	my $class=shift @_;
	my $SourceUrl=shift @_;

	
	
	my $this={};
	$this->{sourceUrl}=$SourceUrl;	
	$this->{title}=$defaultTitle;
	$this->{author}=$defaultAuthor;
	$this->{date}=$defaultDate;
	$this->{content}=$defaultContent;
	$this->{type}=$defaultType;
	$this->{genre}=$defaultGenre;
	$this->{xip}=$defaultXip;

	
	bless($this, $class);
	return $this;
	
}

# METHODE parse()
# Lance l’analyse de xip, et enregistre le résultat dans la propriété xip

sub parse {
	
}

# METHODE toXml()
# Renvoie une string, contenu le document en XML “<doc> … </doc>” (DTD du cours), avec le header
sub toXML {
	
	my $this=shift @_;
	my $id=shift @_;
	# Générer le nom du doc XML à créer
	my $XMLFile="@{$this->{sourceUrl}}"."_"."$id".".xml";
	print $XMLFile."\n";
	# Répertoire de sauvegarde du doc XML
	my $XMLPath="corpus_test"."/xml"."/doc";
	print $XMLPath."\n";
	my $sourceFile="$this->{xip}";
	my $fileXML=$sourceFile;
	# chemin complet du fichier
	my $pathFile=$XMLPath."/".$XMLFile;
	#~ my $output = new IO::File(">output6.xml");
	my $output = new IO::File(">".$pathFile);
	my $writer = new XML::Writer( 
	    OUTPUT      => $output,
	    DATA_INDENT => 10,             # indentation, dix espaces
	    DATA_MODE   => 1,             # changement ligne.
	    ENCODING    => 'utf-8',
	);	
	my $compteur=0;
	my %hash;
	my @ID_Lemma;
	#entête	
	$writer->xmlDecl("UTF-8");

#enregistrement
	$writer->startTag("doc");
		$writer->startTag("header");
			$writer->startTag("fileDesc");
				$writer->startTag("titleStmt");
					$writer->emptyTag("title", "value" => "$this->{title}");
					$writer->emptyTag("author", "value" => "$this->{author}");
					$writer->emptyTag("translation", "source_language" => "fr", "source_title" => "$this->{content}", "translator" => "", "date" => "$this->{date}");
				$writer->endTag("titleStmt");
				$writer->startTag("publicationStmt");
					$writer->emptyTag("publisher", "value" => "");
					$writer->emptyTag("pubPlace", "value" => "");
					$writer->emptyTag("pubDate", "value" => "$this->{date}");
					$writer->emptyTag("pubURL", "value" => "@{$this->{sourceUrl}}");
					$writer->emptyTag("pubNumeric", "value" => "");
				$writer->endTag("publicationStmt");
			$writer->endTag("fileDesc");
			$writer->startTag("profileDesc");
				$writer->startTag("langUsage");
					$writer->emptyTag("language", "ident" => "fr");
				$writer->endTag("langUsage");
				$writer->emptyTag("textDesc", "type" => "$this->{type}", "sub_genre" => "$this->{genre}", "thema" => "");
			$writer->endTag("profileDesc");
		$writer->endTag("header");
			$writer->startTag("text");
				$writer->startTag("body");

					open(ENT,"<:encoding(utf8)",$sourceFile);
					while (! eof(ENT)) 
					{
						my $ligne=<ENT>;
						my $line=$ligne;
						if($ligne=~/^<LUNIT.*?/)
						{
							$compteur++;
							my $niveau=0;
							my $find=1;
							my $idw="";
							%hash=();
							#Data Parser					
							while($find==1)
							{
								$find=0;
								#Détecter la structure <token...>...</token> 
								#à chaque fois la structure est détectée on stoke les paramètres (attributs) dans un %hash{$niveau}-->$valeur et on supprime la structure;
								#Repeter jusqu'à on trouve plus des TOKEN dans la ligne ($find==0).
								#$niveau: un compteur qui indique le niveau de profondeur,
								if ($ligne=~/(.*)<TOKEN (.*?)>(.*?)<\/TOKEN>(.*)/)
								{	
									$find=1;
									print "UpStream:".$1."\n";
									print "VAR1:".$2."\n";
									print "VAR2:".$3."\n";
									print "DownStream:".$4."\n";
									my $temp=$1."#FFF";
									my $v1=$2;
									my $v2=$3;
									$ligne=$1.$4;
									print "Temp Features:".$temp."\n";
									$temp=~s/(.*)<NODE(.*?)>(.*?#FFF)/$3/e;
									print "Temp Befor Clean:".$temp."\n";
									my $f="";
									my $p=0;
									# Détecter les features 
									#forme de sortie Feature1:Feature2:Ffeature3...FeatureN;
									while (($temp=~/(.*)<FEATURE attribute="(.*?)" value="(.*?)"\/>(\#FFF)/))
									{
										$f=$f.":".$2;
										$temp=$1.$4;
										$p++;
										print "Temp F$p:==>:".$f."\n";
									}
									#Construction de la chaine de Features
									$f=~s/(:|::)(.*?)/$2/e;
									$hash{$niveau}=[$v1,$v2,$f];
									$niveau++;
									print "********\n";
								}
								else
								{ 
									#Affichage de %Hash
									# Parcourir le contenu de %Hash, extraire les attribut et ecrire dans le fichier de sortie (XML)
									print "Not a Lot!!\n";
									#~~ Hach Display
									print "******Affichage de Hash******";
									my $j=0;
									while((my $key,my $value) = each %hash)
									{
										$j++;
										print "\nRef_$j\t Clé => $key\t Valeur";
										my $i=0;
										#~ ##foreach $i (sort keys %$pointeur) 
										foreach my $val (@{$value})
										{
											$i++;
											print "Case_$i==>$val --\t--";
											#~ ##**Extraction**
											my $sequence=$val;
											if($sequence=~/(.*?)<READING lemma="(.*?)" pos="(.*?)".*/)
											{
												print "\n\t\t\t\t\t\t extract==> Form=$1\tLem=$2\tCat=$3\n\n";
												
											}										
											#~ ##**End Extraction**
										}
									}							
									#Data Writer
										print "==> Start Paragraph Writer\n";
																		
										#~ Section Header
										$writer->startTag( "p", "id" => "$compteur","type"=>"title");
										$writer->startTag( "s", "id" => "$compteur","offset"=>"");
										print "\tEntet Statement ==>(id=$compteur)\n";
										#~ Section Content	
										# Start Section
										$writer->startTag( "tc");
										# Start Token Writer
										my $level=$niveau;									
										print "==> Start Token insertion ################# $niveau\n";
										my $ID_Lemma=[];
										while ($niveau>0)
										{
											#Write Token
											print "\tToken Extraction...!\n";
											my $sentence=$hash{$niveau}[1];
											my $feature=$hash{$niveau}[2];
											print "\tTraited sentence==>$hash{$niveau}[1]\n";
											if($sentence=~/(.*?)<READING lemma="(.*?)" pos="(.*?)".*/)
											{
												my $id=$level-$niveau;
												my $lemme=$2;
												$writer->startTag("t", "id" => "$id", "c" => "$3", "l" => "$2", "f" => "$feature", "e" => " ");
												$writer->characters($1);
												$writer->endTag("t");
												print "\tToken Writed ==> (Form=\"$1\"\tLem=\"$2\"\tCat=\"$3\")\n";
												$ID_Lemma[$id]=$lemme;
																												
											}
											$niveau--;
										}
										#~End of Section
										$writer->endTag("tc");
										#~Start Dependency 
										print "==> Start Dependency\n";
										$writer->startTag( "dc");
										# Déterminer les dépandances contenus dans le ligne en cours de traitement
										my %DEP=	Dependency($line);										
										 $niveau=1;
										my $u=keys(%DEP);
										while ($u>0)
										{
											# Les Attributs de la structure <dc> </dc>
											my $name=$DEP{$u}[0];
											my $var1=$DEP{$u}[1];
											my $word=@{$var1}[2];
											# Renvoyer l'id du mot en dépandance
											$idw=getWordID($word,\@ID_Lemma);
											$writer->startTag("d", "t" => "$name", "h" => "$idw", "d" => "$niveau");
											$writer->endTag("d");
											print "\tDpendency Inserted! (XML)\n";
											$u--;
											$niveau++;
										}
										#~End of Dependency
										$writer->endTag("dc");
										#~close Declarating (s & p) 
										$writer->endTag("s");
										$writer->endTag("p");
								}
							}
							print "OUT: Fragment finished !!\n";
						}else 
						{print "PASSED LINE !\n";}
						
					}
					print "END OF FILE !\n";


				#fin de la structure
				# Fermeture dess Balises
				$writer->endTag("body");
			$writer->endTag("text");
	$writer->endTag("doc");
	$writer->end();
	$output->close();
	open(FILE,"<:encoding(utf8)",$pathFile);
	my @lignes =<FILE>;
	my $doc=join("",@lignes);
	close(FILE);
	return $doc;
	
}

sub Dependency{
	#Extraire les dépendances dans le ligne en entrée
	# Entrée ($ligne): Ligne traité
	#Sortie (%DEP): %hash qui contient les variables de dépandances extraites
	my $ligne=shift;
	my $find=1;
	my %hash;
	my $niveau=1;
	#Etape1: La détection de la structure de dépandance;
	# Action: Dépandance détectée (<DEPENDENCY></DEPENDENCY>)==> enregistrée dans %DEP  ==> Supprimée de la ligne
	# Repeter (Action) jusqu'à Plus de structure <DEPENDENCY>..</DEPENDENCY> dans le ligne traité
	while ($find==1)
	{
		$find=0;
		##print $ligne;
		if($ligne=~/(.*)<DEPENDENCY name="(.*?)">(.*?)<\/DEPENDENCY>(.*)/)
		{	
			
			$find=1;
			$hash{$niveau}=[$2,$3];
			$ligne=$1.$4;
			$niveau++;
			print "Out: Detected DEP ($2, $3)\n";
			
			
		}else {print "Out: UNDETECTED DEP!!!!\n";}
	}
	print "END DEP Extract For Unit!\n";
	##Extract DEP Entity
	#Etape2: Extraire les attributs contenus dans la strcture <DEPENDENCY> <\/DEPENDENCY>
	my %DEP;
	my $vc=0;
	while((my $key,my $value) = each %hash)
		{
				
			my $name=@{$value}[0];
			my $contained=@{$value}[1];
			
			print "=======> Given Key value $key=> $name _ $contained\n";
			$contained=~s/<FEATURE(.*?)\/>(.*?)/$2/e;
			print "\t\t\t\t\t Traited Contained==> $contained\n";
			if($contained=~/<PARAMETER ind="(.*?)" num="(.*?)" word="(.*?)"\/><PARAMETER ind="(.*?)" num="(.*?)" word="(.*?)"\/>/)
			{
				my $dep1=[$1,$2,$3];
				my $dep2=[$4,$5,$6];
				$DEP{$key}=[$name,$dep1,$dep2];
				print "\t\t\t\t\t\t=>DEP Archived! ($1--$2--$3--$4--$5--$6)\n";
				
			}
				
		}
		
		return %DEP;

##END SUB
}


sub getWordID{
	#renvoyer l'id de mot dans le %hash ()
	my $w=shift;
	my $Tab=shift;
	my $elt="";
	my $i=0;
	my $id;
	foreach $elt (@{$Tab})
	{
		if ($elt eq $w)
		{
			$id=$i;
		}
		$i++;
		
	}
	
	return $id;
	}

