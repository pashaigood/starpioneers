import type { ReactNode } from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import Roadmap from '@site/src/components/Roadmap';
import styles from './index.module.css';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/summary/">
            🚀 Начать изучение
          </Link>
          <Link
            className="button button--primary button--lg"
            to="/factions/"
            style={{ marginLeft: '1rem' }}>
            🌌 Фракции 2218
          </Link>
        </div>
      </div>
    </header>
  );
}

function HomepageFeatures() {
  const features = [
    {
      title: '🌍 Богатая вселенная',
      description: 'Погрузитесь в детально проработанный мир 2218 года с его фракциями, технологиями и политикой межзвёздной колонизации.',
    },
    {
      title: '⚔️ Системы игры',
      description: 'Изучите игровые механики: от боевой системы до экономики, квестов и симуляции живого мира.',
    },
    {
      title: '🎨 UI/UX дизайн',
      description: 'Ознакомьтесь с интерфейсами игры и принципами дизайна для создания захватывающего пользовательского опыта.',
    },
  ];

  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {features.map((feature, idx) => (
            <div key={idx} className="col col--4">
              <div className="card" style={{ padding: '2rem', height: '100%', textAlign: 'center' }}>
                <h3 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>{feature.title}</h3>
                <p style={{ color: '#a0aec0' }}>{feature.description}</p>
              </div>
            </div>
          ))}
        </div>

        <div style={{ marginTop: '4rem', textAlign: 'center' }}>
          <h2 style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>
            Звёздные Пионеры
          </h2>
          <p style={{ fontSize: '1.2rem', color: '#a0aec0', maxWidth: '800px', margin: '0 auto' }}>
            Исследуйте неизведанные системы в эпоху первых межзвёздных путешествий.
            Каждое решение формирует судьбу колоний и отношения с фракциями в борьбе за контроль над новым миром.
          </p>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <div className="homepage-starfield">
      <Layout
        title={`${siteConfig.title}`}
        description="Документация по дизайну игры Star Pioneers - Звёздные Пионеры">
        <HomepageHeader />
        <main>
          <Roadmap />
          <HomepageFeatures />
        </main>
      </Layout>
    </div>
  );
}
