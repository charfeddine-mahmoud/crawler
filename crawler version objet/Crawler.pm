package Crawler;


use strict;
use locale;
use Encode;
use IO::Handle;
use LWP::Simple;

# Instructions exécutées au chargement
BEGIN {
	print STDOUT "Chargement du module Crawler\n";
	STDOUT->autoflush();
}

END {
	# instructions pour faire le ménage....
}

#**************************************************** Variables

our $initUrl="http://www.lemonde.fr/politique/article/2012/11/06/hausse-de-tva-sociale-quand-le-president-desavoue-le-candidat_1786270_823448.html";
our $defaultMaxDepth=3;
our $defaultMaxProcessedUrl=50;
our $defaultDelay=0.1;
our $defaultUrl2processPattern=".*";
our $defaultUrlNot2crawlPattern='^$';

my %processedUrl;	# hachage indiquant dans ses clés si une url a déjà été traitée
my %inStack;		# hachage indiquant dans ses clés si une url a déjà été empilée


#**************************************************** Méthodes

# constructeur de l'objet Crawler
sub new {
	my $class=shift @_;
	my $initUrl=shift @_;
	my $processFunc=shift @_;
	
	my $this={};
	$this->{initUrl}=$initUrl;	
	$this->{maxDepth}=$defaultMaxDepth;
	$this->{maxProcessedUrl}=$defaultMaxProcessedUrl;
	$this->{delay}=$defaultDelay;
	$this->{url2processPattern}=$defaultUrl2processPattern;
	$initUrl=~/https?:\/\/([^\/]+)/;
	$this->{url2crawlPattern}=$1;
	$this->{urlNot2crawlPattern}=$defaultUrlNot2crawlPattern;
	$this->{processFunc}=$processFunc;
	
	bless($this, $class);
	return $this;
}




# ex. "./../article.html"
# -> http://www.lemonde.fr/politique/article/2012/11/article.html

# on initialise la fonction de traitement
my $process = sub {
	my $url=shift;
	print $url."\n";
};

# Méthode lançant l'exécution d'un session de crawling
sub run {
	my $this=shift @_;

	# pile Url2process <- ()
	my @url2process=();
	# NbProcessedUrl <- 0
	my $nbProcessedUrl=0;
	# on empile (InitUrl,0) dans url2process
	    for (my $i=0; $i< @{$this->{initUrl}};$i++)            # pour chaque site
	{
		print "$this->{initUrl}->[$i]->{domain}"."\n" ;
	push(@url2process,[$this->{initUrl}->[$i]->{domain},0]);
	}

	# tant que InitUrl n'est pas vide faire {
	LOOP:while (@url2process) {
		
		#~ print "Etat de la pile :\n".join("\n",map {"[".join(",",@{$_})."]"} @url2process)."\n";
		
		sleep($this->{delay});
	#	(CurrentUrl,Depth) <- depiler Url2process
		my ($currentUrl,$currentDepth)=@{pop(@url2process)};
	#	Page <- telechargement de currentUrl
		my $currentPage=get($currentUrl);
	#	traiter(Page,CurrentUrl)
	    for (my $i=0; $i< @{$this->{url2processPattern}};$i++)            # pour chaque site
	{
		if ($currentUrl=~/$this->{url2processPattern}->[$i]->{ok}/) {
			$this->{processFunc}->($currentUrl,$currentPage);
		}
	}
	#	incrementer NbProcessedUrl
		$nbProcessedUrl++;
	#	si (NbProcessedUrl>= MaxProcessedUrl) {
		if ($nbProcessedUrl>= $this->{maxProcessedUrl}) {
			last LOOP;	# sortie du tant que
		}
		
	#	ajouter CurrentUrl dans le tableau ProcessedUrl
		$processedUrl{$currentUrl}=1;
	#	si (Depth < MaxDepth) {
		if ($currentDepth < $this->{maxDepth}) {
	#		NewUrls <- extraire de Page tous les hyperliens
			my @links=extractLinks($currentPage);
			my $baseUrl=baseUrl($currentPage,$currentUrl);
			my @newUrls=calcUrl($baseUrl,\@links);

	#		pour chaque NewUrl de NewUrls faire {
			foreach my $newUrl (@newUrls) {
	#			si (NewUrl pas dans %inStack) {
				#~ if (! exists($inStack{$newUrl})) {
				if (! exists($processedUrl{$newUrl})) {
					# si la nouvelle url satisfait aux patterns de filtrage du crawling
					 for (my $i=0; $i< @{$this->{urlNot2crawlPattern}};$i++)            # pour chaque site
					{
						if ($newUrl=~/$this->{url2crawlPattern}/ && $newUrl!~/$this->{urlNot2crawlPattern}->[$i]->{no}/) {
			#				empiler  (NewUrl,Depth+1) dans Url2process
							push(@url2process,[$newUrl ,$currentDepth+1]);
							$inStack{$newUrl}=1;
						}
					}
				}
			}
		}
	}
}
#**************************************************** fonctions


# Fonction pour l'extraction des hyperliens de la page
# Entrées :
# arg1 : string -> une page web

# Sorties
# retour : liste de string

sub extractLinks {
	my $page=shift @_;
	
	my @links;
	
	while ($page=~/<a .*?href\s*=\s*(["'])(.*?)\1/sig) {
		push(@links,$2);
	}
	
	return @links;
}

# Fonction de calcul de l'url de base pour les chemins relatifs
# Entrées :
# arg1 : string -> une page Web
# arg2 : string -> une url complète

# Sorties :
# retour : string -> l'url de base 
# Exemple : pour "http://www.lemonde.fr/politique/article/2012/11/06/hausse-de-tva-sociale-quand-le-president-desavoue-le-candidat_1786270_823448.html#debrief"
# on renvoie "http://www.lemonde.fr/politique/article/2012/11/06/"
# Exemple 2 : pour "http://twitter.com/lemondefr/"
# on renvoie : "http://twitter.com/lemondefr"
sub baseUrl {
	my $page=shift @_;
	my $url=shift @_;
	
	# cas où l'url de base est spécifiée dans le <head>
	if ($page=~/<base .*?href\s*=\s*(["'])(.*?)\1/) {
		return $2;
	}
	
	if ($url=~/	(
				https?:\/\/[^\/]+\/ 	# protocole + nom de domaine
				(.*\/)?			# chemin optionnel
				)
				[\w\-%]+\.\w+		# nom du fichier
				(\x23[\w\-%]+)?	# ancre nommée optionnelle
				(\?[\w\-%&=]+)?	# donnée get optionnelle
				$/ix) {
		return $1;
	}
	$url=~s/([^\/])$/$1\//;
	return $url;
}

# Fonction permettant de transformer la liste d'urls relatives en urls absolues
# Entrées :
# arg1 : 
sub calcUrl {
	my $baseUrl=shift @_;
	my $adrLinks=shift @_;
	my @l=@{$adrLinks};
	my @urls;
	my $domain;
	
	if ($baseUrl=~/(https?:\/\/[^\/]+)/) {
		$domain=$1;
	} else {
		warn "Anomalie\n";
		return ();
	}
	
	# foreach my $link (@{$adrLinks}) {
	foreach my $link (@l) {
		# cas 1 : le lien est déjà absolu
		if ($link=~/^http/) {
			push (@urls,$link);
		}
		# cas 2 : le lien est relatif, mais à partir de la racine du site
		elsif ($link=~/^\//) {
			push (@urls,$domain.$link);
		}
		# cas 3 : le lien est relatif à partir de $baseUrl
		elsif ($link=~/^[.\w\-]/) {
			my $url=$baseUrl.$link;
			# on remplace : 
			# http://lemonde.fr/doc/../politique par 
			# http://lemonde.fr/politique
			$url=~s/\/[^\/]+\/[.][.]\//\//g;
			push (@urls,$baseUrl.$link);
		}
	}
	
	return @urls;
}