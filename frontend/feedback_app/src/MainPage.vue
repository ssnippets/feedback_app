<script>
import { ref, computed, onMounted, getCurrentInstance } from "vue";

const API_LOC=process.env.VUE_APP_API_LOC;


export default {
  data() {
    return {
      sender: "",
      message: "",
      lastId: 0,
    };
  },
  methods: {
    handleSubmit(e) {
      e.preventDefault();
      let f = confirm("Submitting message: " + this.message);
      if (f) {
        console.log({ sender: this.sender, message: this.message });
        this.submitData();
        this.fetchData();
      }
    },
    submitData() {
      return fetch(API_LOC + "/add_msg", {
        method: "post",
        headers: {
          "content-type": "application/json",
        },
        body: JSON.stringify({
          message: this.message,
          sender: this.sender,
          offset: this.lastId,
        }),
      })
        .then((res) => {
          // a non-200 response code
          if (!res.ok) {
            // create error instance with HTTP status text
            const error = new Error(res.statusText);
            error.json = res.json();
            throw error;
          }

          return res.json();
        })
        .then((json) => {
          console.log(json);
        })
        .catch((err) => {
          this.error.value = err;
          // In case a custom JSON error response was provided
          if (err.json) {
            return err.json.then((json) => {
              // set the JSON response message
              this.error.value.message = json.message;
            });
          }
        });
    },
  },
  setup() {
    const data = ref(null);
    const loading = ref(true);
    const error = ref(null);

    function fetchData() {
      loading.value = true;
      return fetch(API_LOC + "/messages", {
        method: "get",
        headers: {
          "content-type": "application/json",
        },
      })
        .then((res) => {
          // a non-200 response code
          if (!res.ok) {
            // create error instance with HTTP status text
            const error = new Error(res.statusText);
            error.json = res.json();
            throw error;
          }

          return res.json();
        })
        .then((json) => {
          // set the response data
          //   let rtv = json.data;
          //   rtv.sort((a,b) => {return a.id-b.id});
          data.value = json.data.sort((a, b) => {
            return a.id - b.id;
          });
        })
        .catch((err) => {
          error.value = err;
          // In case a custom JSON error response was provided
          if (err.json) {
            return err.json.then((json) => {
              // set the JSON response message
              error.value.message = json.message;
            });
          }
        })
        .then(() => {
          loading.value = false;
        });
    }

    onMounted(() => {
      fetchData();
    });

    return {
      data,
      loading,
      error,
      fetchData,
      formatDate: (_d) => {
        const d = new Date(_d);
        const options = {
          weekday: "long",
          year: "numeric",
          month: "long",
          day: "numeric",
        };
        const rtv = d.toLocaleDateString("en-US", options);

        return rtv;
      },
    };
  },
};
</script>

<template>
  <main>
    <h1>Montgomery County Feedback</h1>
    <p>Instructions for using this ...</p>

    <form>
      <label for="sender">Sender Email</label>
      <input v-model="sender" type="text" />

      <label for="message">Message to submit:</label>
      <textarea cols="50" rows="10" v-model="message" />

      <button @click="handleSubmit">Submit</button>
    </form>
    <div>Message to be sent: "{{ sender }}" - "{{ message }}"</div>
    <h2>Messages</h2>
    <!-- <p>{{data}}</p> -->
    <!-- <ul> -->

    
    <table>
        <tr v-for="msg in data" :key="msg.id">
            <td class="msg msgTime">{{ formatDate(msg.createdAt) }}</td>
            <td class="msg msgSender"> {{msg.sender}} </td>
            <td class="msg msgMsg"> {{msg.message}} </td>
        </tr>
    </table>
    
    <!-- TODO: Page counts.... -->
  </main>
</template>

<style>
@import "./assets/base.css";

form {
  /* Center the form on the page */

  width: 50em;
  /* Form outline */
  padding: 1em;
  border: 1px solid #ccc;
  border-radius: 1em;
}

form input {
  width: 50%;
}

form input {
  display: block;
}
form textarea {
  display: block;
}
</style>