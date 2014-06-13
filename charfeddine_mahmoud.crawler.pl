use strict;
use locale;
use Encode;
use IO::Handle;
STDOUT->autoflush();    #pour faire un affichage line par line resultat par resultat
use LWP::Simple;

#**************************************************** Main

my $initUrl="http://new-web-services.com";
my $maxDepth=3;
my $maxProcessedUrl=100;
my $delay=0.1;
my $url2processPattern=".*";
my $url2crawlPattern="lemonde[.]fr";
my $urlNot2crawlPattern='^$';
my %processedUrl;
my %inStack;           #indique si une url �tait d�ja trait�


# ex. "./../article.html"
# -> http://www.lemonde.fr/politique/article/2012/11/article.html

# on initialise la fonction de traitement
my $process = sub {
	my $url=shift;
	print $url."\n";
};

# pile Url2process <- ()
my @url2process=();
# NbProcessedUrl <- 0
my $nbProcessedUrl=0;
# on empile (InitUrl,0) dans url2process
push(@url2process,[$initUrl,0]);
# tant que InitUrl n'est pas vide faire {
LOOP:while (@url2process) {
#        pour qu'on soit pas tr�s agressif avec le site par les requettes
	sleep($delay);
#	(CurrentUrl,Depth) <- depiler Url2process
	my ($currentUrl,$currentDepth)=@{pop(@url2process)};
#	Page <- telechargement de currentUrl
	my $currentPage=get($currentUrl);
#	traiter(Page,CurrentUrl)
	$process->($currentUrl,$currentPage);
#	incrementer NbProcessedUrl
	$nbProcessedUrl++;
#	si (NbProcessedUrl>= MaxProcessedUrl) {
#		sortir du tantque
#	}
	if ($nbProcessedUrl>$maxProcessedUrl) {
		last LOOP;
	}
#	ajouter CurrentUrl dans le tableau ProcessedUrl
	$processedUrl{$currentUrl}=1;
#	si (Depth < MaxDepth) {
	if ($currentDepth<$maxDepth) {
#		NewUrls <- extraire de Page tous les hyperliens
		my @links=extractLinks($currentPage);
		my $baseUrl=baseUrl($currentPage,$currentUrl);
		my @newUrls=calcUrl($baseUrl,\@links);
		edilou(%processedUrl);
		#~ print join("\n",@newUrls);
#		pour chaque NewUrl de NewUrls faire {
		foreach my $newUrl (@newUrls){
#			si (NewUrl pas dans ProcessedUrl) {
			if (!  exists($processedUrl{$newUrl})) {
#				empiler  (NewUrl,Depth+1) dans Url2process
				push(@url2process,[$newUrl,$currentDepth+1]);
#			}
			}
#		}
		}
#	}
	}
#}
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
sub edilou {
	my $proc=shift @_;
	foreach my $p ($proc) {
		print "processedUrl : ".$p."\n";
	}
	
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