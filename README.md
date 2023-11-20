Yoto-Music
===

NB: For the time being, this will only work out-of-the-box on a Mac due to the reliance on `pbpaste`.

Setup:
---

You will need two entries in `.env`:

    YOTO_SESSION_TOKEN='hGiiJUI1isIRcIIpVsmpC6kFkRt...'
    YOTO_USER_ID='auth0|xxxxxxxxxxxxxxxxxxxxxxxx'

You can grab these out of the debugger panel in your browser on any XHR request.

Usage:
---

Start by running...

    ./scrape-pasteboard.sh

in order to populate `links.txt` with however many supported URLs you copy into your pasteboard.

Once you have enough links for your liking, run...

    bash sync.sh links.txt m4a $cardId "$cardTitle"

where `$cardId` is a new/unimportant card from [My playlists](https://my.yotoplay.com/my-cards).
