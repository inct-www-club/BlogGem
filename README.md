WWW部 Webページシステム
=======

これは、[さんだぶWebサイト][sandabu]向けに、ブログシステムである[BlogGem][bloggem]をforkしてつくられたCGIシステムです。

Ruby
----
このシステムはプログラミング言語[Ruby][ruby]、およびそのDSLである[Sinatra][sinatra]を主に利用しています。  
システムをいじる際には、その辺を事前に学んでおいてください。

外部依存関係
-------
このシステムは多数の外部モジュールを利用しています。  
すべてRubyGemsをつかって導入することができます。  
システムの初期導入時には事前にGemのインストールを行ってください。

+  **Sinatra**
   ``gem install sinatra``  
   内部DSLエンジン

+  **ActiveRecord**
   ``gem install activerecord``  
   データベースをオブジェクト的に扱うためのモジュール

+  **haml**
   ``gem install haml``  
   HTMLを平易に記述するためのマークアップ言語

+  **sqlite3**
   ``gem install sqlite3``  
   データベースエンジン

+  **bcrypt**
   ``gem install bcrypt``  
   暗号化エンジン

ライセンス
-------

このシステムは[MIT Lisence][MIT]の下で部員その他関係者に公開するものとします。  
  
ライセンスの下、利用者はソースコードの利用・改変・再配布等を自由にすることができます。  
詳しくは``MIT Lisence``で検索する、もしくは``LISENCE``ファイルを参照してください。  

[ruby]: https://www.ruby-lang.org/ja/
[sinatra]: http://www.sinatrarb.com/intro-jp.html
[bloggem]: http://github.com/NKMR6194/BlogGem
[sandabu]: http://sandabu.net
[MIT]: http://www.opensource.org/licenses/mit-license.php
[bootstrap]: http://getbootstrap.com/
