<script setup>
// import { Todo, Meta } from 'components/models';
// import ExampleComponent from 'components/ExampleComponent.vue';
import { ref } from 'vue';

const history = ref('Example');
</script>

<template>
  <q-page class="row items-center justify-evenly">
    <q-card class="text-blue-grey-10 bg-grey-1">
      <q-card-section>
        <div class="text-h6">Our Changing Planet</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ history }}</div>
      </q-card-section>
    </q-card>
    <q-card class="text-blue-grey-10 bg-grey-1">
      <q-card-section>
        <div class="text-h6">Our Changing Planet</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ history }}</div>
      </q-card-section>
    </q-card>
    <q-card class="text-blue-grey-10 bg-grey-1">
      <q-card-section>
        <div class="text-h6">Our Changing Planet</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ history }}</div>
      </q-card-section>
    </q-card>
  </q-page>
</template>
