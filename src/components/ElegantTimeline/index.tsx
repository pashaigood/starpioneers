import React from 'react';
import styles from './styles.module.css';

// Elegant horizontal development timeline – clean NASA‑style UI
const steps = [
    { title: 'Прототип', description: 'Быстрый прототип базовых систем' },
    { title: 'Тест', description: 'Отладка и полировка' },
    { title: 'Интеграция', description: 'Сведение модулей в игру' },
    { title: 'Баланс', description: 'Тонкая настройка геймплея' },
    { title: 'Релиз', description: 'Финальная проверка и публикация' },
];

const ElegantTimeline: React.FC = () => (
    <section className={styles.timelineSection} aria-label="Горизонтальная дорожная карта разработки">
        <div className={styles.baseLine} />
        {steps.map((step, idx) => (
            <div
                key={idx}
                className={styles.stepWrapper}
                style={{ left: `calc(${(idx / (steps.length - 1)) * 100}% + 2rem)` }}
            >
                <div className={styles.dot} />
                <div className={styles.title}>{step.title}</div>
                <div className={styles.description}>{step.description}</div>
            </div>
        ))}
    </section>
);

export default ElegantTimeline;
