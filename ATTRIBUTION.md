# Atıf / Attribution

## Türkçe

Bu repo, **courselabs/devsecops** çalışmasından türetilmiştir.

- **Özgün eser:** [DevSecOps Course Labs](https://github.com/courselabs/devsecops)
- **Özgün yazar:** [Elton Stoneman](https://github.com/sixeyed) — *Learn Docker
  in a Month of Lunches* ve *Learn Kubernetes in a Month of Lunches* kitaplarının
  yazarı
- **Özgün yayın:** https://devsecops.courselabs.co
- **Lisans:** [Creative Commons Attribution-ShareAlike 4.0 International](LICENSE)
  (CC BY-SA 4.0)
- **Türetildiği sürüm:** `70fab83` (21 Aralık 2021) — bu repoda
  `upstream-baseline` etiketiyle işaretlidir

CC BY-SA 4.0 lisansı gereği:

1. Özgün yazara atıf yapılmıştır (bu dosya).
2. Yapılan değişiklikler belirtilmiştir (aşağıdaki liste ve
   [MODERNIZASYON.md](MODERNIZASYON.md)).
3. Bu türetilmiş eser **aynı lisansla** (CC BY-SA 4.0) dağıtılmaktadır.

### Yapılan değişiklikler

Özgün eser Aralık 2021'den beri güncellenmedi. Bu repoda:

- Tüm `docker-compose` (v1) çağrıları `docker compose` (v2) olarak değiştirildi
- Container imajları güncel sürümlere taşındı (ayrıntılı liste:
  [`VERSIONS.yaml`](https://github.com/yasinoz/labs-platform/blob/main/VERSIONS.yaml))
- Çalışmayan/kaldırılmış API kullanan kurulum manifestleri yenilendi
  (ArgoCD, OPA Gatekeeper)
- Türkçe çeviriler eklendi (`*.tr.md`)
- Lab doğrulama altyapısı eklendi (`.github/workflows/`)
- Jenkins lab ortamı kendi imajımızla yeniden kuruldu (Blue Ocean yerine
  yerleşik Pipeline arayüzü)
- Ekran yönlendirmeleri güncel arayüzlere göre yeniden yazıldı

Bu değişiklikler **özgün yazarın onayı veya katılımı olmadan** yapılmıştır;
hatalar bu reponun sorumluluğundadır, courselabs'in değil.

---

## English

This repository is derived from **courselabs/devsecops**.

- **Original work:** [DevSecOps Course Labs](https://github.com/courselabs/devsecops)
- **Original author:** [Elton Stoneman](https://github.com/sixeyed) — author of
  *Learn Docker in a Month of Lunches* and *Learn Kubernetes in a Month of Lunches*
- **Original site:** https://devsecops.courselabs.co
- **Licence:** [Creative Commons Attribution-ShareAlike 4.0 International](LICENSE)
  (CC BY-SA 4.0)
- **Derived from:** commit `70fab83` (21 December 2021), tagged
  `upstream-baseline` in this repository

As required by CC BY-SA 4.0: the original author is credited, the changes are
documented (see above and [MODERNIZASYON.md](MODERNIZASYON.md)), and this
derivative work is distributed under the **same licence**.

Changes were made **without the involvement or endorsement of the original
author**. Any errors introduced here are the responsibility of this repository,
not of courselabs.

### Related upstream work

Parts of the original labs were themselves adapted from other courselabs
repositories, which are also CC BY-SA 4.0:

- [Docker](https://github.com/courselabs/docker)
- [Kubernetes](https://github.com/courselabs/kubernetes)
- [Observability](https://github.com/courselabs/observability)
