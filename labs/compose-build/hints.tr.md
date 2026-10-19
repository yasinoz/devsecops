# Lab İpuçları

İmaj etiketleri sıklıkla uygulama sürümleri için kullanılır ve
[semantik sürümleme](https://semver.org) yaklaşımı çok yaygındır.

Aynı imaj için birden fazla etiketiniz olabilir:

- `1` — ana sürüm (major)
- `1.0` — ana + ikincil sürüm (major + minor)
- `1.0.100` — ana + ikincil sürüm + build numarası

Bu, kullanıcıların belirli bir sürüme sabitlenmesine imkân verir — `1.0.100`
asla değişmez.

İkincil sürümler her build ile güncellenir — `1.0` şu an `1.0.100` ama önümüzdeki
ay `1.0.126` için takma ad olabilir.

Ana sürümler her build **ve** her ikincil sürüm güncellemesiyle değişir — `1`
şu an `1.0.100`, ama gelecek yıl `1.2.407` olabilir.

RNG uygulaması buna benzer bir yaklaşım kullanıyor.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
