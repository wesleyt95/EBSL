import { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    children: [{ path: '', component: () => import('pages/IndexPage.vue') }],
  },
  {
    path: '/games',
    component: () => import('layouts/MainLayout.vue'),
    children: [
      { path: '', component: () => import('pages/games/MainScoreboard.vue') },
      {
        name: 'games',
        path: ':id',
        component: () => import('pages/games/GameIndex.vue'),
      },
    ],
  },
  {
    path: '/teams',
    component: () => import('layouts/MainLayout.vue'),
    children: [
      { path: '', component: () => import('pages/teams/TeamsPage.vue') },
      { path: ':id', component: () => import('pages/teams/TeamIndex.vue') },
    ],
  },
  {
    path: '/players',
    component: () => import('layouts/MainLayout.vue'),
    children: [
      { path: ':id', component: () => import('pages/players/PlayerIndex.vue') },
    ],
  },

  // Always leave this as last one,
  // but you can also remove it
  {
    path: '/:catchAll(.*)*',
    component: () => import('pages/ErrorNotFound.vue'),
  },
];

export default routes;
