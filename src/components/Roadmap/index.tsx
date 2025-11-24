import React, { useState } from 'react';
import styles from './styles.module.css';

interface Feature {
    name: string;
    status: 'completed' | 'active' | 'planned';
}

interface RoadmapPhase {
    id: number;
    title: string;
    status: 'completed' | 'active' | 'planned';
    icon: string;
    features: Feature[];
}

const roadmapData: RoadmapPhase[] = [
    {
        id: 1,
        title: 'Прототип 1',
        status: 'completed',
        icon: '🚀',
        features: [
            { name: 'Механики полёта', status: 'completed' },
            { name: 'Генерация планет', status: 'completed' },
            { name: 'Экономика и торговля', status: 'completed' },
        ],
    },
    {
        id: 2,
        title: 'Прототип 2',
        status: 'active',
        icon: '🚀',
        features: [
            { name: 'Базовая кастомизация', status: 'active' },
            { name: 'Система прогрессии', status: 'active' },
            { name: 'Космический бой', status: 'active' },
            { name: 'Динамические квесты', status: 'planned' },
        ],
    },
    {
        id: 3,
        title: 'Вселенная',
        status: 'planned',
        icon: '🌌',
        features: [
            { name: 'Система фракций', status: 'planned' },
            { name: 'Звёздные системы', status: 'planned' },
            { name: 'Прыжковые двигатели', status: 'planned' },
        ],
    },

    {
        id: 5,
        title: 'Планета',
        status: 'planned',
        icon: '🌍',
        features: [
            { name: 'Планетарное строительство', status: 'planned' },
            { name: 'Квесты поселений', status: 'planned' },
        ],
    },
    {
        id: 4,
        title: 'Конфликты',
        status: 'planned',
        icon: '⚔️',
        features: [
            { name: 'Пиратство', status: 'planned' },
            { name: 'Войны фракций', status: 'planned' },
            { name: 'Охота за головами', status: 'planned' },
        ],
    },
    {
        id: 6,
        title: 'Нарратив',
        status: 'planned',
        icon: '📖',
        features: [
            { name: 'Основная кампания', status: 'planned' },
            { name: 'Персонажи', status: 'planned' },
            { name: 'Ветвящиеся сюжеты', status: 'planned' },
            { name: 'База квестов', status: 'planned' },
        ],
    },
    {
        id: 7,
        title: 'Расширение',
        status: 'planned',
        icon: '🔧',
        features: [
            { name: 'Новые системы', status: 'planned' },
            { name: 'Классы кораблей', status: 'planned' },
            { name: 'Продвинутая кастомизация', status: 'planned' },
        ],
    },
    {
        id: 8,
        title: 'Запуск',
        status: 'planned',
        icon: '🎯',
        features: [
            { name: 'Оптимизация', status: 'planned' },
            { name: 'Балансировка', status: 'planned' },
            { name: 'Локализация', status: 'planned' },
            { name: 'Релиз', status: 'planned' },
        ],
    },
];

export default function Roadmap(): React.JSX.Element {
    const [activePhase, setActivePhase] = useState<number | null>(null);

    return (
        <section className={styles.roadmapSection}>
            <div className="container">
                <h2 className={styles.roadmapTitle}>Дорожная карта разработки</h2>
                <p className={styles.roadmapSubtitle}>
                    Путь к звёздам: основные этапы создания Star Pioneers
                </p>

                <div className={styles.roadmapContainer}>
                    <div className={styles.timeline}>
                        {roadmapData.map((phase, index) => (
                            <div key={phase.id} className={styles.phaseWrapper}>
                                {/* Connection Line */}
                                {index < roadmapData.length - 1 && (
                                    <div className={`${styles.connectionLine} ${styles[phase.status]}`} />
                                )}

                                {/* Phase Node */}
                                <div
                                    className={`${styles.phaseNode} ${styles[phase.status]} ${activePhase === phase.id ? styles.expanded : ''
                                        }`}
                                    onClick={() => setActivePhase(activePhase === phase.id ? null : phase.id)}
                                    onKeyDown={(e) => {
                                        if (e.key === 'Enter' || e.key === ' ') {
                                            setActivePhase(activePhase === phase.id ? null : phase.id);
                                        }
                                    }}
                                    role="button"
                                    tabIndex={0}
                                >
                                    <div className={styles.hexagon}>
                                        <span className={styles.icon}>{phase.icon}</span>
                                    </div>
                                    <div className={styles.phaseTitle}>{phase.title}</div>

                                    {/* Status Badge */}
                                    <div className={styles.statusBadge}>
                                        {phase.status === 'completed' && '✅'}
                                        {phase.status === 'active' && '🔄'}
                                        {phase.status === 'planned' && '📋'}
                                    </div>
                                </div>

                                {/* Expanded Details */}
                                {/* Expanded Details – always visible */}
                                <div className={styles.phaseDetails}>
                                    <ul className={styles.featureList}>
                                        {phase.features.map((feature, idx) => (
                                            <li key={idx} className={styles.featureItem}>
                                                <span className={styles.bullet}>
                                                    {feature.status === 'completed' ? '✅' : feature.status === 'active' ? '🔄' : '📋'}
                                                </span>
                                                {feature.name}
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Legend */}
                <div className={styles.legend}>
                    <div className={styles.legendItem}>
                        <span className={styles.legendIcon}>✅</span>
                        <span>Готово</span>
                    </div>
                    <div className={styles.legendItem}>
                        <span className={styles.legendIcon}>🔄</span>
                        <span>В разработке</span>
                    </div>
                    <div className={styles.legendItem}>
                        <span className={styles.legendIcon}>📋</span>
                        <span>Запланировано</span>
                    </div>
                </div>
            </div>
        </section>
    );
}
