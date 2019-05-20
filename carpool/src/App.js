import React from 'react';
import './App.css';
import Sidebar from "react-sidebar";
import { Jumbotron, Container } from 'react-bootstrap';
import Bigarea from './components/bigarea/Bigarea'

class App extends React.Component {

  render() {
    return (
      <div>


        <Jumbotron fluid>
          <Container>
            <h1>Fluid jumbotron</h1>
            <p>
              This is a modified jumbotron that occupies the entire horizontal space of
              its parent.
            </p>
          </Container>
        </Jumbotron>
        <Bigarea></Bigarea>





      </div>

    )
  }
}

export default App;
