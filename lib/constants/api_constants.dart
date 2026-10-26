const String kBaseUrl = 'https://vercelapi-gamma.vercel.app';
const int kDefaultLimit = 15;

const String kSearchSongsEndpoint = '/api/search/songs';
const String kSearchAlbumsEndpoint = '/api/search/albums';
const String kSearchArtistsEndpoint = '/api/search/artists';
const String kSongsEndpoint = '/api/songs';
const String kAlbumsEndpoint = '/api/albums';
const String kArtistsEndpoint = '/api/artists';
const String kPlaylistsEndpoint = '/api/playlists';
const String kTrendingQuery = 'latest hindi';

// Backwards-compatible aliases
const String baseUrl = kBaseUrl;
const int defaultLimit = kDefaultLimit;
const String searchSongsEndpoint = kSearchSongsEndpoint;
const String searchAlbumsEndpoint = kSearchAlbumsEndpoint;
const String songsEndpoint = kSongsEndpoint;
const String albumsEndpoint = kAlbumsEndpoint;
const String playlistsEndpoint = kPlaylistsEndpoint;
const String trendingQuery = kTrendingQuery;
