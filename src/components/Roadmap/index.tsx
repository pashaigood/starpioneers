import React, { useState } from 'react';
import styles from './styles.module.css';

interface RoadmapPhase {
    id: number;
    title: string;
    status: 'completed' | 'active' | 'planned';
    icon: string;
    features: string[];
}

const roadmapData: RoadmapPhase[] = [
    {
        id: 1,
        title: 'Прототип 1',
        status: 'completed',
        icon: '🚀',
        features: [
            'Механики полёта',
            'Генерация планет',
            'Экономика и торговля',
        ],
    },
    {
        id: 2,
        title: 'Прототип 2',
        status: 'active',
        icon: '🚀',
        features: [
            'Базовая кастомизация',
            'Система прогрессии',
            'Космический бой',
            'Динамические квесты',
        ],
    },
    {
        id: 3,
        title: 'Вселенная',
        status: 'planned',
        icon: '🌌',
        features: [
            'Система фракций',
            'Звёздные системы',
            'Прыжковые двигатели',
        ],
    },
    {
        id: 4,
        title: 'Конфликты',
        status: 'planned',
        icon: '⚔️',
        features: [
            'Пиратство',
            'Войны фракций',
            'Охота за головами',
        ],
    },
    {
        id: 5,
        title: 'Нарратив',
        status: 'planned',
        icon: '📖',
        features: [
            'Основная кампания',
            'Персонажи',
            'Ветвящиеся сюжеты',
        ],
    },
    {
        id: 6,
        title: 'Расширение',
        status: 'planned',
        icon: '🔧',
        features: [
            'Новые системы',
            'Классы кораблей',
            'Продвинутая кастомизация',
        ],
    },
    {
        id: 7,
        title: 'Запуск',
        status: 'planned',
        icon: '🎯',
        features: [
            'Оптимизация',
            'Балансировка',
            'Локализация',
            'Релиз',
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
                                                <span className={styles.bullet}>{phase.status === 'completed' ? '✅' : phase.status === 'active' ? '🔄' : '📋'}</span>
                                                {feature}
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
