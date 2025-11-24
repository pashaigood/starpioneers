import React from 'react';
import styles from './styles.module.css';

// Horizontal development timeline – clean, professional UI with white dots
const steps = [
    { title: 'Прототип', description: 'Быстрый прототип базовых систем' },
    { title: 'Тест', description: 'Отладка и полировка' },
    { title: 'Интеграция', description: 'Сведение модулей в игру' },
    { title: 'Баланс', description: 'Тонкая настройка геймплея' },
    { title: 'Релиз', description: 'Финальная проверка и публикация' },
];

const DevelopmentTimeline: React.FC = () => (
    <section className={styles.timelineSection} aria-label="Горизонтальная дорожная карта разработки">
        <div className={styles.line} />
        {steps.map((step, idx) => (
            <div key={idx} className={styles.dotWrapper} style={{ left: `${(idx / (steps.length - 1)) * 100}%` }}>
                <div className={styles.dot} />
                <div className={styles.label}> {step.title} </div>
                <div className={styles.description}> {step.description} </div>
            </div>
        ))}
    </section>
);

export default DevelopmentTimeline;
