use Crawler;


my $myFunc= sub {
	my ($url,$page)=@_;
	print $url."\n";
};
 my $listeUrl=[
			{
				domain=>'http://www.lemonde.fr',
				ok=>'/article|economie/',
				no=>'\.blog\.',
			},
			{
				domain=>'http://new-web-services.com',
				ok=>'',
				no=>'',
			}
			
];
my $crawlLemonde=Crawler->new($listeUrl,$myFunc);
#~ my $crawlLemonde=Crawler::new("Crawler","http://www.lemonde.fr");
	$crawlLemonde->{url2processPattern}=$listeUrl;
	$crawlLemonde->{urlNot2crawlPattern}=$listeUrl;
print "profondeur max par défaut : ".$Crawler::defaultMaxDepth."\n";
$crawlLemonde->run();
#~ Crawler::run($crawlLemonde);